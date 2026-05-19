# frozen_string_literal: true

module Mapping
  module Review
    class Confirm
      VariantNotFound = Class.new(StandardError)

      def self.call(merchant:, mapping_id:)
        new(merchant: merchant, mapping_id: mapping_id).call
      end

      def initialize(merchant:, mapping_id:)
        @merchant = merchant
        @mapping_id = mapping_id
      end

      def call
        mapping = FindReviewMapping.call(merchant: @merchant, mapping_id: @mapping_id)
        variant = find_suggested_variant!(mapping)
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

      def find_suggested_variant!(mapping)
        variant = if mapping.platform_variant_id.present?
          @merchant.variants.active.find_by(platform_variant_id: mapping.platform_variant_id)
        end
        variant ||= @merchant.variants.active.find_by(master_sku: mapping.master_sku) if mapping.master_sku.present?
        raise VariantNotFound, "Suggested variant not found" unless variant

        variant
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
