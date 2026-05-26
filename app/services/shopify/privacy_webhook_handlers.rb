# frozen_string_literal: true

module Shopify
  # In-memory handlers for mandatory GDPR webhooks (app-level via shopify.app.toml).
  # Not registered with ShopifyAPI::Webhooks::Registry — shopify_api blocks API registration.
  module PrivacyWebhookHandlers
    TOPIC_PATHS = {
      "customers/data_request" => "webhooks/customers_data_request",
      "customers/redact" => "webhooks/customers_redact",
      "shop/redact" => "webhooks/shop_redact"
    }.freeze

    class << self
      def register!
        @handlers = {
          "customers/data_request" => CustomersDataRequestHandler.new,
          "customers/redact" => CustomersRedactHandler.new,
          "shop/redact" => ShopRedactHandler.new
        }.freeze
      end

      def handler_for(topic)
        handlers[topic]
      end

      def topics
        handlers.keys
      end

      private

      def handlers
        @handlers ||= {}
      end
    end
  end
end
