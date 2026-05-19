# frozen_string_literal: true

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  before_action :verify_shopify_webhook
  before_action :parse_webhook_body

  def product_create
    process_product_upsert
    head :ok
  end

  def product_update
    process_product_upsert
    head :ok
  end

  def product_delete
    merchant = find_merchant
    if merchant
      Variant.where(
        merchant_id: merchant.id,
        platform_variant_id: extract_variant_ids(@webhook_body)
      ).update_all(status: "deleted", updated_at: Time.current)
    end

    head :ok
  end

  def self.sync_product_from_webhook(shop_domain:, product:)
    merchant = Merchant.find_by(platform_domain: shop_domain)
    return unless merchant

    upsert_product_variants(merchant, product)

    Rails.logger.info(
      "[Webhook] product upsert merchant=#{merchant.id} " \
      "variants=#{product["variants"]&.size || 0}"
    )
  end

  def self.mark_product_variants_deleted(shop_domain:, product:)
    merchant = Merchant.find_by(platform_domain: shop_domain)
    return unless merchant

    variant_ids = product["variants"]&.map { |v| v["id"].to_s } || []
    return if variant_ids.empty?

    Variant.where(
      merchant_id: merchant.id,
      platform_variant_id: variant_ids
    ).update_all(status: "deleted", updated_at: Time.current)

    Rails.logger.info(
      "[Webhook] product delete merchant=#{merchant.id} " \
      "variants=#{variant_ids.size}"
    )
  end

  private

  def process_product_upsert
    merchant = find_merchant
    return unless merchant

    self.class.upsert_product_variants(merchant, @webhook_body)
  end

  def self.upsert_product_variants(merchant, product)
    upsert_data = []

    product["variants"]&.each do |variant|
      upsert_data << {
        merchant_id: merchant.id,
        product_title: product["title"],
        variant_title: variant["title"],
        master_sku: variant["sku"].presence || "NO_SKU_#{variant["id"]}",
        barcode: variant["barcode"].presence,
        platform: "shopify",
        platform_variant_id: variant["id"].to_s,
        platform_inventory_id: variant["inventory_item_id"].to_s,
        status: "active",
        needs_sku: variant["sku"].blank?,
        synced_at: Time.current
      }
    end

    return if upsert_data.empty?

    Variant.upsert_all(
      upsert_data,
      unique_by: :index_variants_on_merchant_id_and_master_sku,
      update_only: %i[
        product_title variant_title barcode platform platform_variant_id
        platform_inventory_id status needs_sku synced_at
      ]
    )

    Rails.logger.info(
      "[Webhook] product upsert merchant=#{merchant.id} variants=#{upsert_data.size}"
    )
  end
  private_class_method :upsert_product_variants

  def find_merchant
    shop_domain = request.headers["X-Shopify-Shop-Domain"]
    Merchant.find_by(platform_domain: shop_domain)
  end

  def extract_variant_ids(body)
    body["variants"]&.map { |v| v["id"].to_s } || []
  end

  def parse_webhook_body
    @webhook_body = JSON.parse(@webhook_raw_body)
  end

  def verify_shopify_webhook
    @webhook_raw_body = request.body.read
    hmac = request.headers["X-Shopify-Hmac-Sha256"]
    secret = webhook_secret
    digest = OpenSSL::HMAC.digest("sha256", secret, @webhook_raw_body)
    computed = Base64.strict_encode64(digest)

    return if ActiveSupport::SecurityUtils.secure_compare(computed, hmac.to_s)

    Rails.logger.warn("[Webhook] HMAC verification failed")
    head :unauthorized
  end

  def webhook_secret
    Rails.application.credentials.dig(:shopify, :client_secret).presence ||
      ShopifyApp.configuration.secret
  end

  class ProductsCreateHandler
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      WebhooksController.sync_product_from_webhook(shop_domain: data.shop, product: data.body)
    end
  end

  class ProductsUpdateHandler
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      WebhooksController.sync_product_from_webhook(shop_domain: data.shop, product: data.body)
    end
  end

  class ProductsDeleteHandler
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      WebhooksController.mark_product_variants_deleted(shop_domain: data.shop, product: data.body)
    end
  end
end
