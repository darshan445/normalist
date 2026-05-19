# frozen_string_literal: true

module Mapping
  module Review
    class UploadProgress
      def self.record_resolution!(supplier_upload:, supplier_code:, resolved_rows:)
        new(supplier_upload: supplier_upload, supplier_code: supplier_code).record_resolution!(resolved_rows: resolved_rows)
      end

      def initialize(supplier_upload:, supplier_code:)
        @supplier_upload = supplier_upload
        @supplier_code = supplier_code
      end

      def record_resolution!(resolved_rows:)
        return unless @supplier_upload

        @supplier_upload.with_lock do
          prune_output!
          @supplier_upload.update!(
            resolved_count: @supplier_upload.resolved_count + resolved_rows,
            unresolved_count: [ @supplier_upload.unresolved_count - resolved_rows, 0 ].max
          )
          finalize_upload_if_ready!
        end
      end

      private

      def prune_output!
        output = @supplier_upload.output
        return if output.blank?

        @supplier_upload.update!(
          output: output.reject { |row| row["unique_code"] == @supplier_code }
        )
      end

      def finalize_upload_if_ready!
        return unless @supplier_upload.unresolved_count.zero?

        @supplier_upload.update!(status: "completed", stage: "complete", error_message: nil)
      end
    end
  end
end
