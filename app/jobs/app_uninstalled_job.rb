# frozen_string_literal: true

class AppUninstalledJob < ApplicationJob
  def perform(shop_domain:, webhook:)
    merchant = Merchant.find_by(platform_domain: shop_domain)

    if merchant.nil?
      logger.error("#{self.class} failed: cannot find merchant with domain '#{shop_domain}'")
      return
    end

    logger.info("#{self.class} disconnecting Shopify for '#{shop_domain}'")
    merchant.disconnect_shopify!
  end
end
