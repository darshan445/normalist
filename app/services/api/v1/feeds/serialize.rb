# frozen_string_literal: true

module Api
  module V1
    module Feeds
      class Serialize
        def self.call(feed, latest_upload: nil)
          new(feed, latest_upload:).call
        end

        def initialize(feed, latest_upload: nil)
          @feed = feed
          @latest_upload = latest_upload
        end

        def call
          {
            id: feed.id,
            name: feed.name,
            feed_type: feed.feed_type,
            status: feed.status,
            url: feed.google_sheets? ? feed.config["url"] : nil,
            tab_gid: feed.google_sheets? ? feed.config["tab_gid"] : nil,
            tab_name: feed.google_sheets? ? feed.config["tab_name"] : nil,
            interval: feed.google_sheets? ? feed.sync_interval : nil,
            last_upload_at: latest_upload&.created_at&.iso8601,
            upload_enabled: feed.file_upload?,
            latest_upload: latest_upload_payload
          }
        end

        private

        attr_reader :feed, :latest_upload

        def latest_upload_payload
          return unless latest_upload

          Api::V1::SupplierUploads::Serialize.call(latest_upload)
        end
      end
    end
  end
end
