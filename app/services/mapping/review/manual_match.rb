# frozen_string_literal: true

module Mapping
  module Review
    class ManualMatch
      VariantNotFound = Class.new(StandardError)

      def self.call(merchant:, mapping_id:, variant_id:)
        new(merchant: merchant, mapping_id: mapping_id, variant_id: variant_id).call
      end

      def initialize(merchant:, mapping_id:, variant_id:)
        @merchant = merchant
        @mapping_id = mapping_id
        @variant_id = variant_id
      end

      def call
        mapping = FindReviewMapping.call(merchant: @merchant, mapping_id: @mapping_id)
        variant = find_variant!
        upload = mapping.supplier_upload
        quantities = QuantitiesForCode.call(supplier_upload: upload, supplier_code: mapping.supplier_code)

        ApplicationRecord.transaction do
          MappingWriter.confirm!(mapping: mapping, variant: variant)
          enqueue_shopify_updates!(upload: upload, mapping: mapping, quantities: quantities)
          UploadProgress.record_resolution!(
            supplier_upload: upload,
            supplier_code: mapping.supplier_code,
            resolved_rows: resolved_row_count(quantities)
          )
        end

        mapping.reload
      end

      private

      def find_variant!
        @merchant.variants.active.find(@variant_id)
      rescue ActiveRecord::RecordNotFound
        raise VariantNotFound, "Variant not found"
      end

      def enqueue_shopify_updates!(upload:, mapping:, quantities:)
        return unless upload

        quantities.each do |quantity|
          Shopify::InventoryUpdateJob.perform_later(
            @merchant.id,
            upload.id,
            mapping.id,
            quantity
          )
        end
      end

      def resolved_row_count(quantities)
        count = quantities.size
        count.positive? ? count : 1
      end
    end
  end
end
