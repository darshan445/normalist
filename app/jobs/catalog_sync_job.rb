# frozen_string_literal: true

class CatalogSyncJob < ApplicationJob
  queue_as :default

  def perform(merchant_id)
    merchant = Merchant.find_by(id: merchant_id)

    return unless merchant
    return if merchant.access_token.blank?

    merchant.with_shopify_session do |session|
      sync_catalog(merchant, session)
    end
  rescue ShopifyApp::RefreshTokenExpiredError => e
    Rails.logger.error(
      "[CatalogSyncJob] refresh token expired merchant=#{merchant_id} " \
      "error=#{e.message}"
    )
    raise
  rescue StandardError => e
    Rails.logger.error(
      "[CatalogSyncJob] failed merchant=#{merchant_id} error=#{e.message}"
    )
    raise
  end

  private

  def sync_catalog(merchant, session)
    ShopifyAPI::Context.activate_session(session)

    rows = Shopify::CatalogPull.call(session: session)
    upsert_data = rows.map do |row|
      {
        merchant_id: merchant.id,
        product_title: row.product_title,
        variant_title: row.variant_title,
        master_sku: row.master_sku,
        barcode: row.barcode,
        platform: "shopify",
        platform_variant_id: row.platform_variant_id,
        platform_inventory_id: row.platform_inventory_id,
        status: "active",
        needs_sku: row.needs_sku,
        synced_at: Time.current
      }
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
      "[CatalogSyncJob] merchant=#{merchant.id} " \
      "upserted=#{upsert_data.size} " \
      "no_sku=#{no_sku_count}"
    )
  ensure
    ShopifyAPI::Context.deactivate_session
  end

  def fetch_and_save_location(merchant, session)
    location_id = Shopify::PrimaryLocation.call(session: session)
    return if location_id.blank?

    merchant.update!(location_id: location_id)

    Rails.logger.info(
      "[CatalogSyncJob] location saved location_id=#{location_id}"
    )
  end
end
