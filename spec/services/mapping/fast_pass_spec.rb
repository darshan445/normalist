# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mapping::FastPass do
  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant: merchant) }
  let(:upload) { create(:supplier_upload, merchant: merchant, supplier: supplier) }
  let!(:profile) do
    create(:supplier_profile,
      merchant: merchant,
      supplier: supplier,
      unique_column: "SKU",
      quantity_column: "QTY",
      barcode_column: "UPC")
  end
  let!(:variant) { create(:variant, merchant: merchant, master_sku: "MASTER-1", barcode: "111222") }
  let(:rows) do
    [
      { "SKU" => "DICT-1", "QTY" => "10", "UPC" => "999" },
      { "SKU" => "NEW-1", "QTY" => "5", "UPC" => "111222" },
      { "SKU" => "UNKNOWN", "QTY" => "3", "UPC" => "" }
    ]
  end

  before do
    file = double(
      attached?: true,
      open: nil,
      filename: double(to_s: "stocks.csv")
    )
    allow(file).to receive(:open).and_yield(StringIO.new("stub"))
    allow(Ingestion::FileNormalizer).to receive(:call).and_return(rows)
    allow(upload).to receive(:file).and_return(file)
    allow(Shopify::InventoryUpdateJob).to receive(:perform_later)
  end

  it "resolves mapped dictionary rows and enqueues Shopify updates" do
    mapping = create(:mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_code: "DICT-1",
      master_sku: "MASTER-1",
      status: "mapped")

    allow(Ingestion::FileNormalizer).to receive(:call).and_return([rows.first])
    result = described_class.call(upload: upload)

    expect(result.resolved_count).to eq(1)
    expect(mapping.reload.pending_quantity).to eq(10)
    expect(Shopify::InventoryUpdateJob).to have_received(:perform_later).with(
      merchant.id,
      upload.id,
      mapping.id
    )
  end

  it "creates mapped dictionary entries and enqueues Shopify when a variant matches" do
    allow(Ingestion::FileNormalizer).to receive(:call).and_return([rows.second])
    result = described_class.call(upload: upload)

    mapping = MappingDictionary.find_by!(merchant: merchant, supplier: supplier, supplier_code: "NEW-1")
    expect(mapping.status).to eq("mapped")
    expect(mapping.master_sku).to eq("MASTER-1")
    expect(mapping.platform_variant_id).to eq(variant.platform_variant_id)
    expect(mapping.platform_inventory_id).to eq(variant.platform_inventory_id)
    expect(result.resolved_count).to eq(1)
    expect(result.unresolved_count).to eq(0)
    expect(mapping.pending_quantity).to eq(5)
    expect(Shopify::InventoryUpdateJob).to have_received(:perform_later).with(
      merchant.id,
      upload.id,
      mapping.id
    )
  end

  it "collects fully unmatched rows in output" do
    result = described_class.call(upload: upload)

    expect(result.unmatched_rows.size).to eq(2)
    expect(result.unmatched_rows.map { |r| r["unique_code"] }).to contain_exactly("DICT-1", "UNKNOWN")
  end

  it "resolves dictionary rows by barcode when unique code is not mapped" do
    create(:mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_code: "111222",
      master_sku: "MASTER-1",
      status: "mapped")

    row = { "SKU" => "ALT-SKU", "QTY" => "7", "UPC" => "111222" }
    allow(Ingestion::FileNormalizer).to receive(:call).and_return([row])

    result = described_class.call(upload: upload)

    expect(result.resolved_count).to eq(1)
  end
end
