# frozen_string_literal: true

module Catalog
  class ShopifyProductSync
    EMBEDDING_ATTRS = %i[product_title variant_title master_sku barcode].freeze

    def self.call(merchant:, product:)
      new(merchant: merchant, product: product).call
    end

    def initialize(merchant:, product:)
      @merchant = merchant
      @product = product
    end

    def call
      to_embed_ids = []
      synced = 0

      product_variants.each do |variant_payload|
        attrs = build_attrs(variant_payload)
        existing = find_existing(variant_payload, attrs)

        if existing
          needs_embed = needs_embedding?(existing, attrs)
          existing.update!(attrs)
          to_embed_ids << existing.id if needs_embed
        else
          record = @merchant.variants.create!(attrs)
          to_embed_ids << record.id
        end

        synced += 1
      end

      if to_embed_ids.any?
        VariantEmbeddingJob.perform_later(@merchant.id, variant_ids: to_embed_ids)
      end

      synced
    end

    private

    def product_variants
      @product["variants"] || []
    end

    def build_attrs(variant)
      {
        product_title: @product["title"],
        variant_title: variant["title"],
        master_sku: variant["sku"].presence || "NO_SKU_#{variant['id']}",
        barcode: variant["barcode"].presence,
        platform: "shopify",
        platform_variant_id: variant["id"].to_s,
        platform_inventory_id: variant["inventory_item_id"].to_s,
        status: "active",
        needs_sku: variant["sku"].blank?,
        synced_at: Time.current
      }
    end

    def find_existing(variant_payload, attrs)
      platform_id = variant_payload["id"].to_s

      @merchant.variants.find_by(platform_variant_id: platform_id) ||
        @merchant.variants.find_by(master_sku: attrs[:master_sku])
    end

    def needs_embedding?(existing, attrs)
      existing.embedding.blank? || embedding_attrs_changed?(existing, attrs)
    end

    def embedding_attrs_changed?(existing, attrs)
      EMBEDDING_ATTRS.any? { |key| existing.public_send(key) != attrs[key] }
    end
  end
end
