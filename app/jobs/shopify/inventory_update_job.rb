# frozen_string_literal: true

module Shopify
  class InventoryUpdateJob < ApplicationJob
    queue_as :shopify_sync

    retry_on Shopify::InventoryWriter::WriteError, wait: :polynomially_longer, attempts: 5

    def perform(merchant_id, supplier_upload_id, mapping_dictionary_id)
      merchant = Merchant.find(merchant_id)
      mapping = MappingDictionary.find_by!(id: mapping_dictionary_id, merchant_id: merchant.id)
      quantity = mapping.pending_quantity
      return if quantity.nil?

      inventory_item_id = mapping.platform_inventory_id.presence ||
        merchant.variants.active.find_by(master_sku: mapping.master_sku)&.platform_inventory_id

      unless merchant.shopify_connected? && inventory_item_id.present?
        Rails.logger.info(
          "[Shopify::InventoryUpdateJob] Skipped upload=#{supplier_upload_id} " \
          "mapping=#{mapping_dictionary_id} (platform not connected or no inventory id)"
        )
        clear_pending_quantity!(mapping)
        return
      end

      InventoryWriter.call(merchant: merchant, mapping: mapping, quantity: quantity)

      Rails.logger.info(
        "[Shopify::InventoryUpdateJob] Synced qty=#{quantity} behavior=#{mapping.quantity_behavior} " \
        "inventory_item=#{inventory_item_id} master_sku=#{mapping.master_sku}"
      )
      clear_pending_quantity!(mapping)
    rescue Shopify::InventoryWriter::NotReady => e
      Rails.logger.warn(
        "[Shopify::InventoryUpdateJob] Not ready upload=#{supplier_upload_id} " \
        "mapping=#{mapping_dictionary_id}: #{e.message}"
      )
      clear_pending_quantity!(mapping)
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.warn("[Shopify::InventoryUpdateJob] Record not found: #{e.message}")
    end

    private

    def clear_pending_quantity!(mapping)
      mapping.update!(pending_quantity: nil) if mapping.pending_quantity.present?
    end
  end
end
