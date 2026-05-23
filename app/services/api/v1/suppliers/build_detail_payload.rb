# frozen_string_literal: true

module Api
  module V1
    module Suppliers
      class BuildDetailPayload
        def self.call(supplier:)
          new(supplier:).call
        end

        def initialize(supplier:)
          @supplier = supplier
        end

        def call
          {
            supplier: Serialize.call(
              supplier,
              mapped_count: mapping_stats[:mapped],
              pending_count: mapping_stats[:pending],
              skipped_count: mapping_stats[:skipped],
              review_count: mapping_stats[:review]
            ),
            mapping_stats: mapping_stats,
            feeds: feeds_payload
          }
        end

        private

        attr_reader :supplier

        def merchant
          supplier.merchant
        end

        def feeds_payload
          latest_uploads = latest_uploads_by_feed_id

          supplier.feeds.order(:name).map do |feed|
            Api::V1::Feeds::Serialize.call(feed, latest_upload: latest_uploads[feed.id])
          end
        end

        def latest_uploads_by_feed_id
          supplier.supplier_uploads
            .where.not(feed_id: nil)
            .order(created_at: :desc)
            .group_by(&:feed_id)
            .transform_values(&:first)
        end

        def mapping_stats
          @mapping_stats ||= supplier.mapping_dictionaries.group(:status).count.then do |counts|
            {
              mapped: counts["mapped"] || 0,
              pending: counts["pending"] || 0,
              skipped: counts["skipped"] || 0,
              review: counts["review"] || 0
            }
          end
        end

      end
    end
  end
end
