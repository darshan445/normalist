# frozen_string_literal: true

module Shopify
  class InventoryUpdateJob < ApplicationJob
    queue_as :shopify_sync

    def perform(merchant_id, supplier_upload_id, mapping_dictionary_id, quantity)
      merchant = Merchant.find(merchant_id)
      mapping = MappingDictionary.find_by!(id: mapping_dictionary_id, merchant_id: merchant.id)
      variant = merchant.variants.active.find_by(master_sku: mapping.master_sku)

      unless merchant.access_token.present? && variant&.platform_inventory_id.present?
        Rails.logger.info(
          "[Shopify::InventoryUpdateJob] Skipped upload=#{supplier_upload_id} " \
          "mapping=#{mapping_dictionary_id} (platform not connected or no inventory id)"
        )
        return
      end

      # Phase 2 enqueue point — Shopify Inventory API write lands in a future change.
      Rails.logger.info(
        "[Shopify::InventoryUpdateJob] Queued qty=#{quantity} for master_sku=#{mapping.master_sku} " \
        "inventory_item=#{variant.platform_inventory_id}"
      )
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.warn("[Shopify::InventoryUpdateJob] Record not found: #{e.message}")
    end
  end
end
