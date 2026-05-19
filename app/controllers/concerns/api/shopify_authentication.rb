# frozen_string_literal: true

module Api
  module ShopifyAuthentication
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_shopify_merchant!
    end

    attr_reader :current_merchant

    private

    def authenticate_shopify_merchant!
      id_token = bearer_token
      shop_domain = shop_from_session_token(id_token)

      if id_token.present? && !merchant_connected?(shop_domain)
        ensure_shopify_install!(id_token)
        shop_domain = shop_from_session_token(id_token)
      end

      shop_domain ||= shop_from_development_param

      unless shop_domain
        render(json: { error: "unauthorized", message: "Missing or invalid Shopify session" }, status: :unauthorized)
        return
      end

      @current_merchant = Merchant.find_by(platform_domain: shop_domain)

      unless @current_merchant&.shopify_connected?
        render(
          json: {
            error: "shop_not_installed",
            message: "Install NormaList for this store to continue",
            shop: shop_domain
          },
          status: :unauthorized
        )
      end
    end

    def ensure_shopify_install!(id_token)
      ShopifyApp::Auth::TokenExchange.perform(id_token)
    rescue ShopifyAPI::Errors::InvalidJwtTokenError, ShopifyAPI::Errors::MissingJwtTokenError => e
      Rails.logger.warn("[Api::ShopifyAuthentication] Invalid session token: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[Api::ShopifyAuthentication] Token exchange failed: #{e.message}")
      nil
    end

    def merchant_connected?(shop_domain)
      return false if shop_domain.blank?

      Merchant.find_by(platform_domain: shop_domain)&.shopify_connected?
    end

    def shop_from_session_token(token = bearer_token)
      return if token.blank?

      payload = ShopifyAPI::Auth::JwtPayload.new(token)
      ShopifyApp::Utils.sanitize_shop_domain(payload.shopify_domain)
    rescue ShopifyAPI::Errors::InvalidJwtTokenError, ShopifyAPI::Errors::MissingJwtTokenError
      nil
    end

    def shop_from_development_param
      return unless Rails.env.development?
      return if params[:shop].blank?

      ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

    def bearer_token
      request.headers["Authorization"]&.match(/\ABearer (.+)\z/i)&.[](1)
    end
  end
end
