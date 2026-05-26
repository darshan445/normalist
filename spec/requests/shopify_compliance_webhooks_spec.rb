# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Shopify mandatory compliance webhooks", type: :request do
  let(:secret) { ShopifyApp.configuration.secret }
  let(:body) do
    {
      shop_id: 954_889,
      shop_domain: "test-store.myshopify.com",
      customer: { id: 191_167, email: "buyer@example.com" },
      orders_requested: [299_938]
    }.to_json
  end

  def compliance_headers(hmac:, topic: "customers/data_request")
    {
      "CONTENT_TYPE" => "application/json",
      "HTTP_X_SHOPIFY_HMAC_SHA256" => hmac,
      "HTTP_X_SHOPIFY_TOPIC" => topic,
      "HTTP_X_SHOPIFY_SHOP_DOMAIN" => "test-store.myshopify.com",
      "HTTP_X_SHOPIFY_API_VERSION" => "2025-10",
      "HTTP_X_SHOPIFY_WEBHOOK_ID" => "1"
    }
  end

  def valid_hmac(payload)
    digest = OpenSSL::HMAC.digest("sha256", secret, payload)
    Base64.strict_encode64(digest)
  end

  describe "POST /webhooks/customers_data_request" do
    it "returns 401 when HMAC header is missing" do
      post "/webhooks/customers_data_request",
        params: body,
        headers: compliance_headers(hmac: nil).except("HTTP_X_SHOPIFY_HMAC_SHA256")

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when HMAC is invalid" do
      post "/webhooks/customers_data_request",
        params: body,
        headers: compliance_headers(hmac: "invalid")

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 200 when HMAC and headers are valid" do
      hmac = valid_hmac(body)

      expect {
        post "/webhooks/customers_data_request",
          params: body,
          headers: compliance_headers(hmac: hmac)
      }.to have_enqueued_job(CustomersDataRequestJob)

      expect(response).to have_http_status(:ok)
    end
  end
end
