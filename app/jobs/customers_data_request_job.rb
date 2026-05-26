# frozen_string_literal: true

class CustomersDataRequestJob < ApplicationJob
  def perform(shop_domain:, webhook:)
    merchant = Merchant.find_by(platform_domain: shop_domain)

    if merchant.nil?
      logger.error("#{self.class} failed: cannot find merchant with domain '#{shop_domain}'")
      return
    end

    Gdpr::CustomerDataCompliance.handle_data_request(merchant: merchant, webhook: webhook)
  end
end
