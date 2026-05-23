# frozen_string_literal: true

module Api
  module V1
    module SupplierUploads
      class Serialize
        def self.call(upload)
          new(upload).call
        end

        def initialize(upload)
          @upload = upload
        end

        def call
          progress = Uploads::StagePresenter.call(@upload)

          {
            id: @upload.id,
            status: @upload.status,
            stage: @upload.stage,
            stage_key: progress[:stage_key],
            stage_label: progress[:stage_label],
            progress_percent: progress[:progress_percent],
            steps: progress[:steps],
            row_count: @upload.row_count,
            total_codes: total_codes,
            resolved_count: @upload.resolved_count,
            unresolved_count: @upload.unresolved_count,
            pending_count: @upload.unresolved_count,
            unmatched_count: Array(@upload.output).size,
            error_message: @upload.error_message,
            created_at: @upload.created_at.iso8601,
            feed_id: @upload.feed_id
          }
        end

        private

        attr_reader :upload

        def total_codes
          return @upload.row_count if @upload.row_count.present?

          counted = @upload.resolved_count.to_i + @upload.unresolved_count.to_i
          counted.positive? ? counted : nil
        end
      end
    end
  end
end
