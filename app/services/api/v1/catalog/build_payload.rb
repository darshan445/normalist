# frozen_string_literal: true

module Api
  module V1
    module Catalog
      class BuildPayload
        VARIANT_LIMIT = 2_000

        def self.call(merchant:, query: nil)
          new(merchant:, query:).call
        end

        def initialize(merchant:, query: nil)
          @merchant = merchant
          @query = query
        end

        def call
          {
            stats: stats_payload,
            variants: variants_payload
          }
        end

        private

        attr_reader :merchant, :query

        def stats_payload
          {
            variants_count: merchant.variants.active.count,
            catalog_synced_at: merchant.catalog_synced_at&.iso8601
          }
        end

        def variants_payload
          scoped_variants.limit(VARIANT_LIMIT).map { |variant| variant_payload(variant) }
        end

        def scoped_variants
          merchant.variants.active.search(query).order(:product_title, :master_sku, :variant_title)
        end

        def variant_payload(variant)
          {
            id: variant.id,
            product_title: variant.product_title,
            variant_title: variant.variant_title,
            master_sku: variant.master_sku,
            barcode: variant.barcode
          }
        end
      end
    end
  end
end
