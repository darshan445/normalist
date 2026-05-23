# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Suppliers::Serialize do
  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant:, name: "Acme Wholesale") }

  it "returns zero counts for a new supplier" do
    expect(described_class.call(supplier)).to eq(
      id: supplier.id,
      name: "Acme Wholesale",
      mapped_count: 0,
      pending_count: 0,
      skipped_count: 0,
      review_count: 0,
      needs_attention_count: 0,
      status: "ok"
    )
  end

  it "uses precomputed counts when provided" do
    create(:mapping_dictionary, merchant:, supplier:, status: "pending")
    create(:mapping_dictionary, merchant:, supplier:, status: "mapped", supplier_code: "A-1")

    expect(
      described_class.call(supplier, mapped_count: 5, pending_count: 2, review_count: 3)
    ).to include(
      mapped_count: 5,
      pending_count: 2,
      review_count: 3,
      needs_attention_count: 5,
      status: "warning"
    )
  end
end
