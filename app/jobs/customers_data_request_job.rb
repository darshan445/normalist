# frozen_string_literal: true

class CustomersDataRequestJob < ApplicationJob
  def perform(shop_domain:, webhook:)
    merchant = Merchant.find_by(platform_domain: shop_domain)

    if merchant.nil?
      logger.error("#{self.class} failed: cannot find merchant with domain '#{shop_domain}'")
      return
    end

    merchant.with_shopify_session do
      # GDPR: export customer data when requested
    end
  end
end
