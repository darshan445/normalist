# frozen_string_literal: true

module Billing
  class AppSubscriptionsUpdateHandler
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      merchant = Merchant.find_by(platform_domain: data.shop)
      return unless merchant

      Billing::WebhookHandler.call(merchant: merchant, payload: data.body)
    end
  end
end
