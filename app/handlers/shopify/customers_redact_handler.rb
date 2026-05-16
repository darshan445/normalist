# frozen_string_literal: true

module Shopify
  class CustomersRedactHandler
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      CustomersRedactJob.perform_later(shop_domain: data.shop, webhook: data.body)
    end
  end
end
