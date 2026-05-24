# frozen_string_literal: true

# Maps shopify_app session storage onto merchants.platform_domain and merchants.access_token.
# See: https://github.com/Shopify/shopify_app/blob/main/docs/shopify_app/sessions.md
module MerchantShopifySession
  extend ActiveSupport::Concern
  include ShopifyApp::ShopSessionStorage

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

      if merchant.has_attribute?(:expires_at)
        merchant.expires_at = auth_session.expires
      end

      if merchant.has_attribute?(:refresh_token)
        merchant.refresh_token = auth_session.refresh_token
      end

      if merchant.has_attribute?(:refresh_token_expires_at)
        merchant.refresh_token_expires_at = auth_session.refresh_token_expires
      end

      merchant.save!
      merchant.id
    end

    private

    def name_from_shop_domain(domain)
      domain.to_s.sub(/\.myshopify\.com\z/i, "").tr("-", " ").titleize
    end
  end

  def api_version
    ShopifyApp.configuration.api_version
  end

  def disconnect_shopify!
    update!(
      access_token: nil,
      expires_at: nil,
      refresh_token: nil,
      refresh_token_expires_at: nil,
      catalog_synced_at: nil
    )
  end

  def shopify_connected?
    platform == "shopify" && access_token.present? && platform_domain.present?
  end

  def needs_expiring_token_migration?
    access_token.present? && refresh_token.blank?
  end
end
