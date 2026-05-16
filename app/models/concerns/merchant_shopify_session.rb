# frozen_string_literal: true

# Maps shopify_app session storage onto merchants.platform_domain and merchants.access_token.
# See: https://github.com/Shopify/shopify_app/blob/main/docs/shopify_app/sessions.md
module MerchantShopifySession
  extend ActiveSupport::Concern

  included do
    alias_attribute :shopify_domain, :platform_domain
    alias_attribute :shopify_token, :access_token

    scope :shopify, -> { where(platform: "shopify") }
  end

  class_methods do
    def store(auth_session, *_args)
      merchant = find_or_initialize_by(platform_domain: auth_session.shop)
      merchant.access_token = auth_session.access_token
      merchant.platform = "shopify"
      merchant.name = merchant.name.presence || name_from_shop_domain(auth_session.shop)
      merchant.save!
      merchant.id
    end

    def retrieve(id)
      construct_shopify_session(find_by(id: id))
    end

    def retrieve_by_shopify_domain(domain)
      construct_shopify_session(find_by(platform_domain: domain))
    end

    def destroy_by_shopify_domain(domain)
      find_by(platform_domain: domain)&.disconnect_shopify!
    end

    private

    def construct_shopify_session(merchant)
      return unless merchant&.access_token.present? && merchant.platform_domain.present?

      ShopifyAPI::Auth::Session.new(
        shop: merchant.platform_domain,
        access_token: merchant.access_token
      )
    end

    def name_from_shop_domain(domain)
      domain.to_s.sub(/\.myshopify\.com\z/i, "").tr("-", " ").titleize
    end
  end

  def api_version
    ShopifyApp.configuration.api_version
  end

  def with_shopify_session(&block)
    ShopifyAPI::Auth::Session.temp(shop: platform_domain, access_token: access_token) do |session|
      yield session
    end
  end

  def disconnect_shopify!
    update!(access_token: nil, catalog_synced_at: nil)
  end

  def shopify_connected?
    platform == "shopify" && access_token.present? && platform_domain.present?
  end
end
