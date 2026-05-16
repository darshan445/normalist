# frozen_string_literal: true

class CustomersRedactJob < ApplicationJob
  def perform(shop_domain:, webhook:)
    merchant = Merchant.find_by(platform_domain: shop_domain)

    if merchant.nil?
      logger.error("#{self.class} failed: cannot find merchant with domain '#{shop_domain}'")
      return
    end

    merchant.with_shopify_session do
      # GDPR: redact customer data
    end
  end
end
