# frozen_string_literal: true

module Catalog
  class ShopifyInventoryItemSync
    def self.call(merchant:, item:)
      new(merchant: merchant, item: item).call
    end

    def initialize(merchant:, item:)
      @merchant = merchant
      @item = item
    end

    def call
      variant = find_variant
      return false unless variant

      attrs = build_attrs
      needs_embed = needs_embedding?(variant, attrs)
      variant.update!(attrs)
      enqueue_embedding(variant) if needs_embed

      Rails.logger.info(
        "[Catalog::ShopifyInventoryItemSync] merchant=#{@merchant.id} " \
        "inventory_item=#{@item['id']} variant=#{variant.id}"
      )

      true
    end

    private

    def find_variant
      inventory_item_id = @item["id"].to_s

      @merchant.variants.find_by(platform_inventory_id: inventory_item_id) ||
        find_and_link_by_sku(inventory_item_id)
    end

    def find_and_link_by_sku(_inventory_item_id)
      sku = @item["sku"].presence
      return if sku.blank?

      variant = @merchant.variants.find_by(master_sku: sku)
      return unless variant&.platform_inventory_id.blank?

      variant
    end

    def build_attrs
      attrs = {
        platform: "shopify",
        platform_inventory_id: @item["id"].to_s,
        synced_at: Time.current
      }

      return attrs unless @item.key?("sku")

      if @item["sku"].present?
        attrs[:master_sku] = @item["sku"]
        attrs[:needs_sku] = false
      else
        attrs[:needs_sku] = true
      end

      attrs
    end

    def needs_embedding?(variant, attrs)
      return true if variant.embedding.blank?
      return false unless attrs.key?(:master_sku)

      variant.master_sku != attrs[:master_sku]
    end

    def enqueue_embedding(variant)
      VariantEmbeddingJob.perform_later(@merchant.id, variant_ids: [variant.id])
    end
  end
end
