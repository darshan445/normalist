# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Review::ProductMetadata do
  describe ".from_variant" do
    it "builds metadata fields from variant columns" do
      variant = build(
        :variant,
        product_title: "Air Runner",
        variant_title: "Black / 9",
        master_sku: "AERO-9",
        barcode: "123"
      )

      payload = described_class.from_variant(variant)

      expect(payload[:unique_code]).to eq("AERO-9")
      expect(payload[:barcode]).to eq("123")
      expect(payload[:color]).to eq("Black")
      expect(payload[:size]).to eq("9")
      expect(payload[:metadata]).to include("Product: Air Runner", "Color: Black", "Size: 9")
    end
  end

  describe ".from_supplier_row" do
    it "extracts optional supplier attribute columns" do
      payload = described_class.from_supplier_row(
        unique_code: "SUP-1",
        barcode: "999",
        raw_row: { "ITEM_NAME" => "Widget", "COLOR" => "Red" },
        schema_map: {
          "supplier_attributes" => {
            "title" => "ITEM_NAME",
            "color" => "COLOR"
          }
        }
      )

      expect(payload[:title]).to eq("Widget")
      expect(payload[:color]).to eq("Red")
      expect(payload[:metadata]).to include("Title: Widget", "Color: Red")
    end
  end
end
