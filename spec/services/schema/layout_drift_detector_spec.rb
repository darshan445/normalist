# frozen_string_literal: true

require "rails_helper"

RSpec.describe Schema::LayoutDriftDetector do
  let(:supplier) { create(:supplier) }

  it "detects drift when no schema map exists" do
    expect(described_class.call(supplier: supplier, incoming_headers: %w[A B])).to be(true)
  end

  it "detects drift when headers change" do
    create(
      :supplier_profile,
      merchant: supplier.merchant,
      supplier: supplier,
      unique_column: "OldSku",
      quantity_column: "OldQty",
      raw_headers: %w[OldSku OldQty]
    )

    expect(described_class.call(supplier: supplier, incoming_headers: %w[NewSku NewQty])).to be(true)
  end

  it "returns false when headers match saved layout" do
    create(
      :supplier_profile,
      merchant: supplier.merchant,
      supplier: supplier,
      unique_column: "ItemCode_Ref",
      quantity_column: "Avail_Qty",
      raw_headers: %w[ItemCode_Ref Avail_Qty]
    )

    expect(described_class.call(supplier: supplier, incoming_headers: %w[ItemCode_Ref Avail_Qty])).to be(false)
  end
end
