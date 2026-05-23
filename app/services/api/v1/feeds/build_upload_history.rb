# frozen_string_literal: true

module Api
  module V1
    module Feeds
      class BuildUploadHistory
        LIMIT = 10

        def self.call(feed:)
          new(feed:).call
        end

        def initialize(feed:)
          @feed = feed
        end

        def call
          uploads = @feed.supplier_uploads.order(created_at: :desc).limit(LIMIT)

          {
            uploads: uploads.map { |upload| history_row(upload) }
          }
        end

        private

        def history_row(upload)
          serialized = Api::V1::SupplierUploads::Serialize.call(upload)

          {
            id: serialized[:id],
            created_at: serialized[:created_at],
            total_codes: serialized[:total_codes],
            resolved_count: serialized[:resolved_count],
            pending_count: serialized[:pending_count],
            status: serialized[:status]
          }
        end
      end
    end
  end
end
