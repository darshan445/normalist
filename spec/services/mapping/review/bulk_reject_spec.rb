# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mapping::Review::BulkReject do
  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant: merchant) }

  before do
    create(
      :mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_code: "SUP-SUG",
      status: "review",
      confidence_score: 0.8
    )
    create(
      :mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_code: "SUP-LOW",
      status: "review",
      confidence_score: 0.2
    )
  end

  it "skips only unsuggested mappings" do
    result = described_class.call(merchant: merchant, supplier_id: supplier.id, suggestion: "unsuggested")

    expect(result.succeeded).to eq(1)
    expect(merchant.mapping_dictionaries.find_by(supplier_code: "SUP-SUG").status).to eq("review")
    expect(merchant.mapping_dictionaries.find_by(supplier_code: "SUP-LOW").status).to eq("skipped")
  end
end
