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

  def inventory_item_create
    process_inventory_item
    head :ok
  end

  def inventory_item_update
    process_inventory_item
    head :ok
  end

  def inventory_level_connect
    process_inventory_level
    head :ok
  end

  def inventory_level_update
    process_inventory_level
    head :ok
  end

  def app_subscriptions_update
    merchant = find_merchant
    return head :ok unless merchant

    Billing::WebhookHandler.call(
      merchant: merchant,
      payload: @webhook_body
    )

    head :ok
  end

  def self.sync_product_from_webhook(shop_domain:, product:)
    merchant = Merchant.find_by(platform_domain: shop_domain)
    return unless merchant

    synced = Catalog::ShopifyProductSync.call(merchant: merchant, product: product)

    Rails.logger.info(
      "[Webhook] product upsert merchant=#{merchant.id} synced=#{synced}"
    )
  end

  def self.sync_inventory_item_from_webhook(shop_domain:, item:)
    merchant = Merchant.find_by(platform_domain: shop_domain)
    return unless merchant

    synced = Catalog::ShopifyInventoryItemSync.call(merchant: merchant, item: item)

    Rails.logger.info(
      "[Webhook] inventory item merchant=#{merchant.id} synced=#{synced}"
    )
  end

  def self.sync_inventory_level_from_webhook(shop_domain:, level:)
    merchant = Merchant.find_by(platform_domain: shop_domain)
    return unless merchant

    synced = Catalog::ShopifyInventoryLevelSync.call(merchant: merchant, level: level)

    Rails.logger.info(
      "[Webhook] inventory level merchant=#{merchant.id} synced=#{synced}"
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
    shop_domain = request.headers["X-Shopify-Shop-Domain"]
    self.class.sync_product_from_webhook(shop_domain: shop_domain, product: @webhook_body)
  end

  def process_inventory_item
    shop_domain = request.headers["X-Shopify-Shop-Domain"]
    self.class.sync_inventory_item_from_webhook(shop_domain: shop_domain, item: @webhook_body)
  end

  def process_inventory_level
    shop_domain = request.headers["X-Shopify-Shop-Domain"]
    self.class.sync_inventory_level_from_webhook(shop_domain: shop_domain, level: @webhook_body)
  end

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
    secret = ShopifyApp.configuration.secret
    digest = OpenSSL::HMAC.digest("sha256", secret, @webhook_raw_body)
    computed = Base64.strict_encode64(digest)

    return if ActiveSupport::SecurityUtils.secure_compare(computed, hmac.to_s)

    Rails.logger.warn("[Webhook] HMAC verification failed")
    head :unauthorized
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

  class InventoryItemsCreateHandler
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      WebhooksController.sync_inventory_item_from_webhook(shop_domain: data.shop, item: data.body)
    end
  end

  class InventoryItemsUpdateHandler
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      WebhooksController.sync_inventory_item_from_webhook(shop_domain: data.shop, item: data.body)
    end
  end

  class InventoryLevelsConnectHandler
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      WebhooksController.sync_inventory_level_from_webhook(shop_domain: data.shop, level: data.body)
    end
  end

  class InventoryLevelsUpdateHandler
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      WebhooksController.sync_inventory_level_from_webhook(shop_domain: data.shop, level: data.body)
    end
  end
end
