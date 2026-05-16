# frozen_string_literal: true

module Shopify
  class AppUninstalledHandler
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      AppUninstalledJob.perform_later(shop_domain: data.shop, webhook: data.body)
    end
  end
end
