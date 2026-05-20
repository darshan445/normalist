# frozen_string_literal: true

module Shopify
  # Writes supplier quantities to Shopify using the Inventory Level REST API.
  # Uses mapping.platform_inventory_id (Shopify inventory_item_id), not the Variant API.
  class InventoryWriter
    NotReady = Class.new(StandardError)
    WriteError = Class.new(StandardError)

    def self.call(merchant:, mapping:, quantity:)
      new(merchant: merchant, mapping: mapping, quantity: quantity).call
    end

    def initialize(merchant:, mapping:, quantity:)
      @merchant = merchant
      @mapping = mapping
      @quantity = quantity.to_i
    end

    def call
      raise NotReady, "merchant is not connected to Shopify" unless @merchant.shopify_connected?

      inventory_item_id = inventory_item_id_for_mapping
      raise NotReady, "missing platform_inventory_id" if inventory_item_id.blank?

      location_id = resolve_location_id!
      raise NotReady, "no Shopify location available" if location_id.blank?

      @merchant.with_shopify_session do |session|
        level = ShopifyAPI::InventoryLevel.new(session: session)
        ensure_connected!(level, inventory_item_id, location_id)
        apply_quantity!(level, inventory_item_id, location_id)
      end

      true
    rescue ShopifyAPI::Errors::HttpResponseError => e
      raise WriteError, "Shopify inventory update failed: #{e.message}"
    end

    private

    def inventory_item_id_for_mapping
      @mapping.platform_inventory_id.presence ||
        @merchant.variants.active.find_by(master_sku: @mapping.master_sku)&.platform_inventory_id
    end

    def resolve_location_id!
      return @merchant.location_id if @merchant.location_id.present?

      @merchant.with_shopify_session do |session|
        locations = ShopifyAPI::Location.all(session: session)
        primary = locations.first
        next unless primary

        location_id = primary.id.to_s
        @merchant.update!(location_id: location_id)
        location_id
      end
    end

    def ensure_connected!(level, inventory_item_id, location_id)
      level.connect(
        inventory_item_id: inventory_item_id,
        location_id: location_id,
        relocate_if_necessary: false
      )
    rescue ShopifyAPI::Errors::HttpResponseError => e
      # Already connected at this location is a common, non-fatal case.
      Rails.logger.info(
        "[Shopify::InventoryWriter] connect skipped inventory_item=#{inventory_item_id} " \
        "location=#{location_id}: #{e.message}"
      )
    end

    def apply_quantity!(level, inventory_item_id, location_id)
      if @mapping.quantity_behavior == "add"
        level.adjust(
          inventory_item_id: inventory_item_id,
          location_id: location_id,
          available_adjustment: @quantity
        )
      else
        level.set(
          inventory_item_id: inventory_item_id,
          location_id: location_id,
          available: @quantity
        )
      end
    end
  end
end
