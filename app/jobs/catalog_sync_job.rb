# frozen_string_literal: true

class CatalogSyncJob < ApplicationJob
  queue_as :default

  def perform(merchant_id)
    merchant = Merchant.find_by(id: merchant_id)

    return unless merchant
    return if merchant.access_token.blank?

    session = ShopifyAPI::Auth::Session.new(
      shop: merchant.platform_domain,
      access_token: merchant.access_token
    )

    ShopifyAPI::Context.activate_session(session)

    upsert_data = []
    page_info = nil

    loop do
      products = ShopifyAPI::Product.all(
        session: session,
        limit: 250,
        page_info: page_info
      )

      products.each do |product|
        product.variants.each do |variant|
          upsert_data << {
            merchant_id: merchant.id,
            product_title: product.title,
            variant_title: variant.title,
            master_sku: variant.sku.presence || "NO_SKU_#{variant.id}",
            barcode: variant.barcode.presence,
            platform: "shopify",
            platform_variant_id: variant.id.to_s,
            platform_inventory_id: variant.inventory_item_id.to_s,
            status: "active",
            needs_sku: variant.sku.blank?,
            synced_at: Time.current
          }
        end
      end

      break unless ShopifyAPI::Product.next_page?

      page_info = ShopifyAPI::Product.next_page_info
    end

    if upsert_data.any?
      Variant.upsert_all(
        upsert_data,
        unique_by: :index_variants_on_merchant_id_and_master_sku,
        update_only: %i[
          product_title variant_title barcode platform platform_variant_id
          platform_inventory_id status needs_sku synced_at
        ]
      )
    end

    fetch_and_save_location(merchant, session)

    merchant.update!(catalog_synced_at: Time.current)
    Catalog::VariantEmbeddingJob.perform_later(merchant.id)

    no_sku_count = upsert_data.count { |v| v[:needs_sku] }

    Rails.logger.info(
      "[CatalogSyncJob] merchant=#{merchant_id} " \
      "upserted=#{upsert_data.size} " \
      "no_sku=#{no_sku_count}"
    )
  rescue StandardError => e
    Rails.logger.error(
      "[CatalogSyncJob] failed merchant=#{merchant_id} " \
      "error=#{e.message}"
    )
    raise
  ensure
    ShopifyAPI::Context.deactivate_session
  end

  private

  def fetch_and_save_location(merchant, session)
    locations = ShopifyAPI::Location.all(session: session)
    primary = locations.first
    return unless primary

    merchant.update!(location_id: primary.id.to_s)

    Rails.logger.info(
      "[CatalogSyncJob] location saved location_id=#{primary.id}"
    )
  end
end
