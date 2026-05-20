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
        ApplicationRecord.transaction do
          MappingWriter.skip!(mapping: mapping)
          UploadProgress.record_resolution!(
            supplier_upload: upload,
            supplier_code: mapping.supplier_code,
            resolved_rows: PendingQuantity.resolved_row_count_for_mapping(mapping)
          )
        end

        mapping.reload
      end

    end
  end
end
