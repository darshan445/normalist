# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Catalog", type: :request do
  let(:merchant) do
    create(
      :merchant,
      platform: "shopify",
      platform_domain: "test-store.myshopify.com",
      access_token: "shpat_test"
    )
  end

  before do
    allow(Rails.env).to receive(:development?).and_return(true)
  end

  describe "GET /api/v1/catalog" do
    it "returns catalog stats and variants" do
      create(:variant, merchant:, product_title: "Air Runner", master_sku: "AERO-1")

      get "/api/v1/catalog", params: { shop: merchant.platform_domain }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["stats"]["variants_count"]).to eq(1)
      expect(response.parsed_body["variants"].first["master_sku"]).to eq("AERO-1")
    end

    it "filters variants with q" do
      create(:variant, merchant:, master_sku: "KEEP-1")
      create(:variant, merchant:, master_sku: "SKIP-1", product_title: "Other")

      get "/api/v1/catalog", params: { shop: merchant.platform_domain, q: "keep" }

      expect(response.parsed_body["variants"].pluck("master_sku")).to eq(["KEEP-1"])
    end
  end
end
