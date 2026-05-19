# frozen_string_literal: true

require "rails_helper"

RSpec.describe Schema::AiSchemaScanner do
  let(:headers) { %w[VND_SKU_NUM UPC_EAN_CODE QTY_AVAILABLE ITEM_NAME] }
  let(:rows) do
    [
      {
        "VND_SKU_NUM" => "SKU-1",
        "UPC_EAN_CODE" => "123",
        "QTY_AVAILABLE" => "5",
        "ITEM_NAME" => "Widget"
      }
    ]
  end

  before do
    allow(Ai::OpenaiClient).to receive(:chat_json).and_return(
      "supplier_unique_column" => "VND_SKU_NUM",
      "supplier_barcode_column" => "UPC_EAN_CODE",
      "supplier_quantity_column" => "QTY_AVAILABLE",
      "supplier_attributes" => {
        "title" => "ITEM_NAME",
        "color" => nil,
        "size" => nil
      }
    )
  end

  it "sends column-oriented row samples to OpenAI" do
    described_class.call(rows: rows)

    expect(Ai::OpenaiClient).to have_received(:chat_json) do |args|
      expect(args[:user_prompt]).to include("Header: VND_SKU_NUM")
      expect(args[:user_prompt]).to include('"SKU-1"')
      expect(args[:user_prompt]).to include("Sample values:")
    end
  end

  it "resolves headers case-insensitively and drops invalid optional mappings" do
    allow(Ai::OpenaiClient).to receive(:chat_json).and_return(
      "supplier_unique_column" => "vnd_sku_num",
      "supplier_barcode_column" => nil,
      "supplier_quantity_column" => "qty_available",
      "supplier_attributes" => {
        "title" => nil,
        "color" => "RED",
        "size" => "S"
      }
    )

    result = described_class.call(rows: rows)

    expect(result["supplier_unique_column"]).to eq("VND_SKU_NUM")
    expect(result["supplier_quantity_column"]).to eq("QTY_AVAILABLE")
    expect(result["supplier_attributes"]["color"]).to be_nil
    expect(result["supplier_attributes"]["size"]).to be_nil
  end

  it "accepts a null title when the file has no description column" do
    allow(Ai::OpenaiClient).to receive(:chat_json).and_return(
      "supplier_unique_column" => "VND_SKU_NUM",
      "supplier_barcode_column" => nil,
      "supplier_quantity_column" => "QTY_AVAILABLE",
      "supplier_attributes" => {
        "title" => nil,
        "color" => nil,
        "size" => nil
      }
    )

    result = described_class.call(rows: rows)

    expect(result["supplier_attributes"]["title"]).to be_nil
  end

  it "returns normalized schema mapping from OpenAI" do
    result = described_class.call(rows: rows)

    expect(result["supplier_unique_column"]).to eq("VND_SKU_NUM")
    expect(result["supplier_barcode_column"]).to eq("UPC_EAN_CODE")
    expect(result["supplier_quantity_column"]).to eq("QTY_AVAILABLE")
    expect(result["supplier_attributes"]["title"]).to eq("ITEM_NAME")
    expect(result["supplier_attributes"]["color"]).to be_nil
  end
end
