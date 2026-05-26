# frozen_string_literal: true

module Shopify
  # Exchanges the embedded session JWT for a fresh offline token without running
  # post-authenticate tasks (webhooks, AfterAuthenticateJob).
  class RefreshOfflineToken
    def self.call(id_token:)
      new(id_token:).call
    end

    def initialize(id_token:)
      @id_token = id_token
    end

    def call
      shop = shop_domain_from_token
      return if shop.blank?

      session = ShopifyAPI::Auth::TokenExchange.exchange_token(
        shop: shop,
        session_token: @id_token,
        requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::OFFLINE_ACCESS_TOKEN
      )

      Merchant.store(session)
      session
    rescue ShopifyAPI::Errors::InvalidJwtTokenError, ShopifyAPI::Errors::MissingJwtTokenError => e
      Rails.logger.warn("[Shopify::RefreshOfflineToken] invalid session token: #{e.message}")
      nil
    rescue ShopifyAPI::Errors::HttpResponseError => e
      Rails.logger.error("[Shopify::RefreshOfflineToken] exchange failed: #{e.message}")
      nil
    end

    private

    def shop_domain_from_token
      domain = ShopifyAPI::Auth::JwtPayload.new(@id_token).shopify_domain
      ShopifyApp::Utils.sanitize_shop_domain(domain)
    end
  end
end
