# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Suppliers", type: :request do
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

  describe "GET /api/v1/suppliers" do
    it "returns suppliers for the merchant" do
      supplier = create(:supplier, merchant:, name: "Supplier A")

      get "/api/v1/suppliers", params: { shop: merchant.platform_domain }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["suppliers"]).to contain_exactly(
        include("id" => supplier.id, "name" => "Supplier A")
      )
    end
  end

  describe "POST /api/v1/suppliers" do
    it "creates a supplier" do
      post "/api/v1/suppliers",
        params: { shop: merchant.platform_domain, supplier: { name: "New Supplier" } }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["supplier"]["name"]).to eq("New Supplier")
      expect(merchant.suppliers.pluck(:name)).to include("New Supplier")
    end

    it "returns validation errors" do
      post "/api/v1/suppliers",
        params: { shop: merchant.platform_domain, supplier: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "GET /api/v1/suppliers/:id" do
    it "returns supplier detail with feeds and mappings" do
      supplier = create(:supplier, merchant:)
      create(:feed, merchant:, supplier:)

      get "/api/v1/suppliers/#{supplier.id}", params: { shop: merchant.platform_domain }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["supplier"]["id"]).to eq(supplier.id)
      expect(response.parsed_body["feeds"]).to be_an(Array)
      expect(response.parsed_body["mapping_stats"]).to include(
        "mapped" => 0,
        "pending" => 0,
        "skipped" => 0,
        "review" => 0
      )
    end

    it "returns not found for another merchant's supplier" do
      other = create(:supplier)

      get "/api/v1/suppliers/#{other.id}", params: { shop: merchant.platform_domain }

      expect(response).to have_http_status(:not_found)
    end
  end
end
