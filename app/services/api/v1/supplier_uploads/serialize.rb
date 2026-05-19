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
          {
            id: upload.id,
            status: upload.status,
            stage: upload.stage,
            resolved_count: upload.resolved_count,
            unresolved_count: upload.unresolved_count,
            unmatched_count: Array(upload.output).size,
            error_message: upload.error_message,
            created_at: upload.created_at.iso8601
          }
        end

        private

        attr_reader :upload
      end
    end
  end
end
