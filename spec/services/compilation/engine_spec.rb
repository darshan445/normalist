require "rails_helper"

RSpec.describe Compilation::Engine do
  let(:variant) { build(:variant, master_sku: "AERO-BLK-09") }

  it "builds V1 output schema" do
    validated = [
      Compilation::Validator::ValidatedRow.new(
        supplier_code: "XYZ-9982",
        quantity: 45,
        master_sku: "AERO-BLK-09",
        variant: variant,
        status: "Ready_To_Sync"
      )
    ]

    needs_review = [
      Struct.new(:supplier_code, :quantity, keyword_init: true).new(
        supplier_code: "UNKNOWN", quantity: 15
      )
    ]

    output = described_class.call(validated_rows: validated, needs_review_rows: needs_review)

    expect(output).to contain_exactly(
      hash_including(
        supplier_code: "XYZ-9982",
        master_sku: "AERO-BLK-09",
        platform_variant_id: nil,
        platform_inventory_id: nil,
        quantity: 45,
        status: "Ready_To_Sync"
      ),
      hash_including(
        supplier_code: "UNKNOWN",
        master_sku: nil,
        status: "Needs_Review"
      )
    )
  end
end
