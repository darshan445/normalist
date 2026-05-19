# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Catalog::BuildPayload do
  subject(:payload) { described_class.call(merchant:, query:) }

  let(:merchant) { create(:merchant) }
  let(:query) { nil }

  describe "stats" do
    it "returns zero counts for an empty catalog" do
      expect(payload[:stats]).to eq(variants_count: 0, catalog_synced_at: nil)
    end

    it "includes catalog_synced_at when set" do
      synced_at = 2.hours.ago.change(usec: 0)
      merchant.update!(catalog_synced_at: synced_at)

      expect(payload[:stats]).to eq(
        variants_count: 0,
        catalog_synced_at: synced_at.iso8601
      )
    end
  end

  describe "variants" do
    it "returns active variants ordered by product title" do
      create(:variant, merchant:, product_title: "Zebra", master_sku: "Z-1")
      create(:variant, merchant:, product_title: "Alpha", master_sku: "A-1")
      create(:variant, merchant:, status: "deleted", master_sku: "DEL-1")

      expect(payload[:variants].pluck(:master_sku)).to eq(%w[A-1 Z-1])
    end

    it "filters by search query" do
      create(:variant, merchant:, product_title: "Air Runner", master_sku: "AERO-1")
      create(:variant, merchant:, product_title: "FoamStep", master_sku: "FOAM-1")

      filtered = described_class.call(merchant:, query: "foam")

      expect(filtered[:variants].pluck(:master_sku)).to eq(["FOAM-1"])
    end
  end
end
