# frozen_string_literal: true

module Shopify
  # Registers mandatory compliance + app webhooks with Shopify after install/token exchange.
  class RegisterWebhooks
    def self.call(shop_domain:)
      new(shop_domain).call
    end

    def initialize(shop_domain)
      @shop_domain = shop_domain
    end

    def call
      return if @shop_domain.blank?

      session = Merchant.retrieve_by_shopify_domain(@shop_domain)
      unless session
        Rails.logger.warn("[Shopify::RegisterWebhooks] no session for shop=#{@shop_domain}")
        return
      end

      return unless ShopifyApp.configuration.has_webhooks?

      ShopifyApp::WebhooksManager.create_webhooks(session: session)
      Rails.logger.info("[Shopify::RegisterWebhooks] webhooks registered shop=#{@shop_domain}")
    rescue StandardError => e
      Rails.logger.error(
        "[Shopify::RegisterWebhooks] failed shop=#{@shop_domain} #{e.class}: #{e.message}"
      )
    end
  end
end
