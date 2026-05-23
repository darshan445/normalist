# frozen_string_literal: true

require "rails_helper"

RSpec.describe Schema::Discovery do
  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant: merchant) }
  let(:upload) { create(:supplier_upload, merchant: merchant, supplier: supplier) }
  let(:rows) do
    [
      { "VND_SKU_NUM" => "SKU-1", "QTY_AVAILABLE" => "5", "ITEM_NAME" => "Widget" }
    ]
  end

  before do
    allow(Ingestion::FileNormalizer).to receive(:call).and_return(rows)
    allow(Schema::AiSchemaScanner).to receive(:call).and_return(
      "supplier_unique_column" => "VND_SKU_NUM",
      "supplier_barcode_column" => nil,
      "supplier_quantity_column" => "QTY_AVAILABLE",
      "supplier_attributes" => {
        "title" => "ITEM_NAME",
        "color" => nil,
        "size" => nil
      }
    )
    allow(upload.file).to receive(:attached?).and_return(true)
    allow(upload.file).to receive(:filename).and_return(instance_double("Filename", to_s: "stocks.xlsx"))
    allow(Ingestion::UploadFileContent).to receive(:call).with(upload).and_return("stub")
  end

  it "persists file_schema_map on supplier profile" do
    result = described_class.call(upload: upload)

    expect(result).to be_success
    expect(result.stage).to eq("Column schema discovered")
    expect(result.row_count).to eq(1)
    expect(result.profile_stage).to eq("ai_detection")

    profile = supplier.reload.supplier_profile
    expect(profile.unique_column).to eq("VND_SKU_NUM")
    expect(profile.quantity_column).to eq("QTY_AVAILABLE")
    expect(profile.file_schema_map["supplier_unique_column"]).to eq("VND_SKU_NUM")
    expect(profile.file_schema_map).not_to have_key("supplier_id")
    expect(profile.raw_headers).to eq(%w[VND_SKU_NUM QTY_AVAILABLE ITEM_NAME])
  end

  it "skips OpenAI when layout has not drifted" do
    create(
      :supplier_profile,
      merchant: merchant,
      supplier: supplier,
      unique_column: "VND_SKU_NUM",
      quantity_column: "QTY_AVAILABLE",
      raw_headers: %w[VND_SKU_NUM QTY_AVAILABLE ITEM_NAME],
      file_schema_map: {
        "raw_headers" => %w[VND_SKU_NUM QTY_AVAILABLE ITEM_NAME],
        "supplier_unique_column" => "VND_SKU_NUM",
        "supplier_quantity_column" => "QTY_AVAILABLE",
        "supplier_attributes" => { "title" => "ITEM_NAME" }
      }
    )

    result = described_class.call(upload: upload)

    expect(result).to be_success
    expect(result.stage).to eq("Column layout unchanged — existing schema kept")
    expect(result.profile_stage).to eq("profile_cache")
    expect(Schema::AiSchemaScanner).not_to have_received(:call)

    profile = supplier.reload.supplier_profile
    expect(profile.last_used_at).to be_present
    expect(profile.raw_headers).to eq(%w[VND_SKU_NUM QTY_AVAILABLE ITEM_NAME])
  end

end
