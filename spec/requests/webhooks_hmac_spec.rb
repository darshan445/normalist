# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Webhook HMAC verification", type: :request do
  let(:merchant) do
    create(
      :merchant,
      platform: "shopify",
      platform_domain: "test-store.myshopify.com",
      access_token: "shpat_test"
    )
  end

  let(:body) do
    {
      id: 1,
      title: "Test Product",
      variants: [{ id: 99_001, sku: "TEST-SKU" }]
    }.to_json
  end

  describe "POST /webhooks/products/create" do
    it "returns 401 when HMAC header is missing" do
      post "/webhooks/products/create",
        params: body,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "HTTP_X_SHOPIFY_SHOP_DOMAIN" => merchant.platform_domain
        }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when HMAC is invalid" do
      post "/webhooks/products/create",
        params: body,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "HTTP_X_SHOPIFY_HMAC_SHA256" => Base64.strict_encode64("bad"),
          "HTTP_X_SHOPIFY_SHOP_DOMAIN" => merchant.platform_domain
        }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 200 when HMAC is valid" do
      allow(WebhooksController).to receive(:sync_product_from_webhook)

      post "/webhooks/products/create",
        params: body,
        headers: shopify_webhook_headers(body, shop_domain: merchant.platform_domain)

      expect(response).to have_http_status(:ok)
      expect(WebhooksController).to have_received(:sync_product_from_webhook).with(
        shop_domain: merchant.platform_domain,
        product: kind_of(Hash)
      )
    end
  end
end
