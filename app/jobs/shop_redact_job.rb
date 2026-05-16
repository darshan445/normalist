# frozen_string_literal: true

class ShopRedactJob < ApplicationJob
  def perform(shop_domain:, webhook:)
    merchant = Merchant.find_by(platform_domain: shop_domain)

    if merchant.nil?
      logger.error("#{self.class} failed: cannot find merchant with domain '#{shop_domain}'")
      return
    end

    logger.info("#{self.class} redacting merchant for '#{shop_domain}'")
    merchant.destroy!
  end
end
