# frozen_string_literal: true

module Mapping
  module Review
    class Reject
      def self.call(merchant:, mapping_id:)
        new(merchant: merchant, mapping_id: mapping_id).call
      end

      def initialize(merchant:, mapping_id:)
        @merchant = merchant
        @mapping_id = mapping_id
      end

      def call
        mapping = FindReviewMapping.call(merchant: @merchant, mapping_id: @mapping_id)
        upload = mapping.supplier_upload
        quantities = QuantitiesForCode.call(supplier_upload: upload, supplier_code: mapping.supplier_code)

        ApplicationRecord.transaction do
          MappingWriter.skip!(mapping: mapping)
          UploadProgress.record_resolution!(
            supplier_upload: upload,
            supplier_code: mapping.supplier_code,
            resolved_rows: resolved_row_count(quantities)
          )
        end

        mapping.reload
      end

      private

      def resolved_row_count(quantities)
        count = quantities.size
        count.positive? ? count : 1
      end
    end
  end
end
