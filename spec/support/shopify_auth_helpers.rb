# frozen_string_literal: true

module ShopifyAuthHelpers
  VALID_TEST_TOKEN = "valid-shopify-session-token"

  def stub_shopify_jwt_auth!(merchant)
    allow(Rails.env).to receive(:development?).and_return(false)

    payload = instance_double(
      ShopifyAPI::Auth::JwtPayload,
      shopify_domain: merchant.platform_domain
    )

    allow(ShopifyAPI::Auth::JwtPayload).to receive(:new) do |token|
      case token
      when VALID_TEST_TOKEN
        payload
      when "invalid-token"
        raise ShopifyAPI::Errors::InvalidJwtTokenError
      else
        raise ShopifyAPI::Errors::MissingJwtTokenError
      end
    end
  end

  def shopify_bearer_headers
    { "Authorization" => "Bearer #{VALID_TEST_TOKEN}" }
  end
end

module ShopifyWebhookHelpers
  def shopify_webhook_headers(body, shop_domain:, secret: ShopifyApp.configuration.secret)
    digest = OpenSSL::HMAC.digest("sha256", secret, body)
    {
      "CONTENT_TYPE" => "application/json",
      "HTTP_X_SHOPIFY_HMAC_SHA256" => Base64.strict_encode64(digest),
      "HTTP_X_SHOPIFY_SHOP_DOMAIN" => shop_domain
    }
  end
end

RSpec.configure do |config|
  config.include ShopifyAuthHelpers, type: :request
  config.include ShopifyWebhookHelpers, type: :request
end
