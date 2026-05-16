# frozen_string_literal: true

module Shopify
  class CustomersDataRequestHandler
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      CustomersDataRequestJob.perform_later(shop_domain: data.shop, webhook: data.body)
    end
  end
end
