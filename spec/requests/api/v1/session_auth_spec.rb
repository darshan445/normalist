# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Session authentication", type: :request do
  let(:merchant) do
    create(
      :merchant,
      platform: "shopify",
      platform_domain: "test-store.myshopify.com",
      access_token: "shpat_test"
    )
  end

  describe "GET /api/v1/session" do
    it "returns 401 without Authorization header" do
      get "/api/v1/session"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("unauthorized")
    end

    it "returns 401 with an invalid Bearer token" do
      get "/api/v1/session", headers: { "Authorization" => "Bearer invalid-token" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when shop is not installed (no access token)" do
      uninstalled = create(
        :merchant,
        platform: "shopify",
        platform_domain: "uninstalled.myshopify.com",
        access_token: nil
      )
      stub_shopify_jwt_auth!(uninstalled)

      get "/api/v1/session", headers: shopify_bearer_headers

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("shop_not_installed")
    end

    it "returns session payload with a valid Bearer token" do
      stub_shopify_jwt_auth!(merchant)

      get "/api/v1/session", headers: shopify_bearer_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "authenticated" => true,
        "merchant" => include(
          "id" => merchant.id,
          "platform_domain" => merchant.platform_domain
        )
      )
    end

    it "does not authenticate another merchant's token as a different shop" do
      other = create(
        :merchant,
        platform: "shopify",
        platform_domain: "other-store.myshopify.com",
        access_token: "shpat_other"
      )
      stub_shopify_jwt_auth!(other)

      get "/api/v1/session", headers: shopify_bearer_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["merchant"]["id"]).to eq(other.id)
      expect(response.parsed_body["merchant"]["id"]).not_to eq(merchant.id)
    end
  end
end
