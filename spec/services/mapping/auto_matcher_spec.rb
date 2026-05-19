require "rails_helper"

RSpec.describe Mapping::AutoMatcher do
  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant: merchant) }
  let!(:variant) { create(:variant, merchant: merchant, master_sku: "AERO-BLK-09", barcode: "1234567890123") }

  it "matches by master SKU and saves dictionary" do
    mapping = create(:mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_code: "AERO-BLK-09",
      status: "pending")

    unresolved = [
      Mapping::DictionaryLookup::UnresolvedRow.new(
        supplier_code: "AERO-BLK-09",
        quantity: 5,
        raw_row: {},
        mapping_dictionary: mapping
      )
    ]

    result = described_class.call(merchant: merchant, supplier: supplier, unresolved_rows: unresolved)

    expect(result[:resolved].size).to eq(1)
    expect(mapping.reload).to have_attributes(status: "mapped", master_sku: "AERO-BLK-09")
  end
end
