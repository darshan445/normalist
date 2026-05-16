require "rails_helper"

RSpec.describe Ai::ProfileInterpreter do
  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant: merchant) }
  let(:rows) do
    [
      { "ItemCode_Ref" => "XYZ-1", "Avail_Qty" => "10" },
      { "ItemCode_Ref" => "XYZ-2", "Avail_Qty" => "20" }
    ]
  end

  before do
    allow(Ai::GeminiClient).to receive(:generate_content).and_return(
      "sku_column" => "ItemCode_Ref",
      "quantity_column" => "Avail_Qty"
    )
  end

  it "updates an existing profile instead of inserting a duplicate" do
    create(:supplier_profile,
      merchant: merchant,
      supplier: supplier,
      sku_column_name: "OldSku",
      quantity_column_name: "OldQty",
      raw_headers: %w[OldSku OldQty])

    described_class.call(merchant: merchant, supplier: supplier, rows: rows)

    profiles = SupplierProfile.where(merchant: merchant, supplier: supplier)
    expect(profiles.count).to eq(1)
    expect(profiles.first.sku_column_name).to eq("ItemCode_Ref")
  end
end
