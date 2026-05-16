# frozen_string_literal: true

module Shopify
  class ShopRedactHandler
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      ShopRedactJob.perform_later(shop_domain: data.shop, webhook: data.body)
    end
  end
end
