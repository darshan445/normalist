# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Dashboard::BuildPayload do
  subject(:payload) { described_class.call(merchant:) }

  let(:merchant) { create(:merchant, name: "Acme Store") }

  describe "stats" do
    it "returns zero counts for an empty merchant" do
      expect(payload[:stats]).to eq(
        variants_count: 0,
        pending_mappings_count: 0,
        suppliers_count: 0
      )
    end

    it "counts active variants, pending mappings, and suppliers" do
      supplier = create(:supplier, merchant:)
      create_list(:variant, 2, merchant:)
      create(:variant, merchant:, status: "deleted")
      create(:mapping_dictionary, merchant:, supplier:, status: "pending")
      create(:mapping_dictionary, merchant:, supplier:, status: "mapped", supplier_code: "ACTIVE-1")
      create(:supplier, merchant:)

      expect(payload[:stats]).to eq(
        variants_count: 2,
        pending_mappings_count: 1,
        suppliers_count: 2
      )
    end
  end

  describe "recent_activity" do
    it "is empty when there are no uploads" do
      expect(payload[:recent_activity]).to eq([])
    end

    it "returns recent uploads with activity status" do
      supplier = create(:supplier, merchant:, name: "Supplier A")
      create(
        :supplier_upload,
        merchant:,
        supplier:,
        status: "completed",
        resolved_count: 45,
        unresolved_count: 0,
        created_at: 2.hours.ago
      )
      create(
        :supplier_upload,
        merchant:,
        supplier:,
        status: "processing",
        stage: "Discovering column schema…",
        created_at: 1.day.ago
      )

      expect(payload[:recent_activity].size).to eq(2)
      expect(payload[:recent_activity].first).to include(
        supplier_name: "Supplier A",
        status: "success"
      )
      expect(payload[:recent_activity].second).to include(
        status: "warning"
      )
    end
  end

  describe "pending_review" do
    it "returns zero count when nothing is pending" do
      expect(payload[:pending_review]).to eq(count: 0, supplier: nil)
    end

    it "returns the supplier with the most pending codes" do
      supplier_a = create(:supplier, merchant:, name: "Supplier A")
      supplier_b = create(:supplier, merchant:, name: "Supplier B")
      create_list(:mapping_dictionary, 2, merchant:, supplier: supplier_a, status: "pending")
      create(:mapping_dictionary, merchant:, supplier: supplier_b, status: "pending", supplier_code: "B-1")

      expect(payload[:pending_review]).to eq(
        count: 3,
        supplier: { id: supplier_a.id, name: "Supplier A" }
      )
    end
  end
end
