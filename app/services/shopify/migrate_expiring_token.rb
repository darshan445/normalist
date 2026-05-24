# frozen_string_literal: true

module Shopify
  class MigrateExpiringToken
    def self.call(merchant:)
      new(merchant:).call
    end

    def initialize(merchant:)
      @merchant = merchant
    end

    def call
      return false unless @merchant.needs_expiring_token_migration?

      new_session = ShopifyAPI::Auth::TokenExchange.migrate_to_expiring_token(
        shop: @merchant.platform_domain,
        non_expiring_offline_token: @merchant.access_token
      )

      Merchant.store(new_session)

      Rails.logger.info(
        "[MigrateExpiringToken] migrated merchant=#{@merchant.id} " \
        "expires_at=#{new_session.expires}"
      )

      true
    rescue ShopifyAPI::Errors::HttpResponseError => e
      Rails.logger.error(
        "[MigrateExpiringToken] failed merchant=#{@merchant.id} error=#{e.message}"
      )
      false
    end
  end
end
