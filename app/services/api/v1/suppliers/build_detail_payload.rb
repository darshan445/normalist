# frozen_string_literal: true

module Api
  module V1
    module Suppliers
      class BuildDetailPayload
        MAPPED_MAPPING_STATUSES = %w[mapped skipped].freeze
        MAPPING_LIMIT = 500

        def self.call(supplier:)
          new(supplier:).call
        end

        def initialize(supplier:)
          @supplier = supplier
        end

        def call
          {
            supplier: Serialize.call(supplier),
            feeds: feeds_payload,
            active_mappings: mapped_mappings_payload,
            active_mappings_total: mapped_mappings_total,
            pending_mappings: pending_mappings_payload,
            review_mappings: review_mappings_payload
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

        def mapped_mappings_payload
          supplier.mapping_dictionaries
            .where(status: MAPPED_MAPPING_STATUSES)
            .order(:supplier_code)
            .limit(MAPPING_LIMIT)
            .map { |row| mapping_row(row) }
        end

        def mapped_mappings_total
          supplier.mapping_dictionaries.where(status: MAPPED_MAPPING_STATUSES).count
        end

        def pending_mappings_payload
          supplier.mapping_dictionaries.pending.order(:supplier_code).map { |row| mapping_row(row) }
        end

        def review_mappings_payload
          supplier.mapping_dictionaries.review.order(:supplier_code).map { |row| mapping_row(row) }
        end

        def mapping_row(row)
          {
            id: row.id,
            supplier_code: row.supplier_code,
            master_sku: row.master_sku,
            status: row.status,
            quantity: nil
          }
        end
      end
    end
  end
end
