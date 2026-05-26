# frozen_string_literal: true

module Gdpr
  # NormaList does not persist Shopify customer PII (orders, emails, etc.).
  # Mandatory GDPR webhooks are acknowledged and logged for Shopify app compliance.
  class CustomerDataCompliance
    POLICY_NOTE = "NormaList does not store Shopify customer personal data."

    def self.handle_data_request(merchant:, webhook:)
      new(merchant, webhook).handle_data_request
    end

    def self.handle_redact(merchant:, webhook:)
      new(merchant, webhook).handle_redact
    end

    def initialize(merchant, webhook)
      @merchant = merchant
      @webhook = normalize_webhook(webhook)
    end

    def handle_data_request
      log_event(
        topic: "customers/data_request",
        customer_ids: extract_customer_ids,
        data_request_id: @webhook.dig("data_request", "id"),
        orders_requested: @webhook["orders_requested"]
      )
    end

    def handle_redact
      log_event(
        topic: "customers/redact",
        customer_ids: extract_customer_ids,
        orders_to_redact: @webhook["orders_to_redact"]
      )
    end

    private

    def normalize_webhook(webhook)
      case webhook
      when Hash then webhook.stringify_keys
      else webhook.to_h.stringify_keys
      end
    end

    def extract_customer_ids
      ids = []
      customer = @webhook["customer"]
      ids << customer["id"] if customer.is_a?(Hash) && customer["id"].present?

      Array(@webhook["customers_to_redact"]).each do |entry|
        ids << entry["id"] if entry.is_a?(Hash) && entry["id"].present?
      end

      ids.compact.map(&:to_s).uniq
    end

    def log_event(topic:, customer_ids:, **extra)
      extras = extra.compact.map { |k, v| "#{k}=#{v.inspect}" }.join(" ")
      Rails.logger.info(
        "[GDPR] #{topic} merchant=#{@merchant.id} shop=#{@merchant.platform_domain} " \
        "customer_ids=#{customer_ids.presence || 'none'} action=no_customer_data_stored " \
        "#{POLICY_NOTE} #{extras}".strip
      )
    end
  end
end
