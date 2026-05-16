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
      shop_domain = shop_from_session_token || shop_from_development_param

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

    def shop_from_session_token
      token = bearer_token
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
