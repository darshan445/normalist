# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Review::BuildQueue do
  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant: merchant) }
  let(:variant) do
    create(
      :variant,
      merchant: merchant,
      master_sku: "MASTER-1",
      platform_variant_id: "pv-1",
      product_title: "Air Runner",
      variant_title: "Black / 9",
      barcode: "111"
    )
  end
  let(:upload) do
    create(
      :supplier_upload,
      merchant: merchant,
      supplier: supplier,
      status: "needs_review",
      unresolved_count: 1,
      output: [{ "unique_code" => "SUP-1", "quantity" => 4 }]
    )
  end

  before do
    create(
      :mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_upload: upload,
      supplier_code: "SUP-1",
      status: "review",
      master_sku: variant.master_sku,
      platform_variant_id: variant.platform_variant_id,
      confidence_score: 0.91
    )
  end

  it "returns review queue items with variant and upload context" do
    payload = described_class.call(merchant: merchant)

    item = payload[:items].first
    expect(item[:supplier_code]).to eq("SUP-1")
    expect(item[:confidence]).to eq(0.91)
    expect(item[:suggested_variant]).to include(
      master_sku: "MASTER-1",
      product_title: "Air Runner",
      barcode: "111"
    )
    expect(item[:supplier_upload]).to include(
      id: upload.id,
      quantities: [4]
    )
    expect(payload[:pagination][:total_count]).to eq(1)
  end

  it "filters by supplier_id when provided" do
    other_supplier = create(:supplier, merchant: merchant)
    create(
      :mapping_dictionary,
      merchant: merchant,
      supplier: other_supplier,
      supplier_code: "OTHER-1",
      status: "review"
    )

    payload = described_class.call(merchant: merchant, supplier_id: supplier.id)

    expect(payload[:items].size).to eq(1)
    expect(payload[:items].first[:supplier_code]).to eq("SUP-1")
  end
end
