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
        PendingQuantity.ensure_on_mapping!(mapping)

        ApplicationRecord.transaction do
          MappingWriter.confirm!(mapping: mapping, variant: variant)
          ShopifyInventoryEnqueue.call(mapping: mapping)
          UploadProgress.record_resolution!(
            supplier_upload: upload,
            supplier_code: mapping.supplier_code
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

    end
  end
end
