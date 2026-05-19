require "rails_helper"

RSpec.describe Mapping::DictionaryLookup do
  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant: merchant) }
  let!(:variant) { create(:variant, merchant: merchant, master_sku: "AERO-BLK-09") }

  it "resolves mapped dictionary mappings" do
    create(:mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_code: "XYZ-9982",
      master_sku: "AERO-BLK-09",
      status: "mapped")

    extracted = [ { supplier_code: "XYZ-9982", quantity: 45, raw_row: {} } ]
    result = described_class.call(merchant: merchant, supplier: supplier, extracted_rows: extracted)

    expect(result[:resolved].size).to eq(1)
    expect(result[:unresolved]).to be_empty
  end

  it "keeps review mappings unresolved until confirmed" do
    create(:mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_code: "REVIEW-1",
      master_sku: "AERO-BLK-09",
      status: "review")

    extracted = [ { supplier_code: "REVIEW-1", quantity: 5, raw_row: {} } ]
    result = described_class.call(merchant: merchant, supplier: supplier, extracted_rows: extracted)

    expect(result[:resolved]).to be_empty
    expect(result[:unresolved].size).to eq(1)
  end

  it "flags unknown codes as unresolved" do
    extracted = [ { supplier_code: "UNKNOWN", quantity: 10, raw_row: {} } ]
    result = described_class.call(merchant: merchant, supplier: supplier, extracted_rows: extracted)

    expect(result[:resolved]).to be_empty
    expect(result[:unresolved].size).to eq(1)
    expect(merchant.mapping_dictionaries.pending.count).to eq(1)
  end
end
