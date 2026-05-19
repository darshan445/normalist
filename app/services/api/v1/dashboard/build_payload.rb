# frozen_string_literal: true

module Api
  module V1
    module Dashboard
      class BuildPayload
        RECENT_UPLOAD_LIMIT = 10
        RECENT_UPLOAD_STATUSES = %w[completed needs_review failed processing pending].freeze

        def self.call(merchant:)
          new(merchant:).call
        end

        def initialize(merchant:)
          @merchant = merchant
        end

        def call
          {
            merchant: merchant_payload,
            stats: stats_payload,
            recent_activity: recent_activity_payload,
            pending_review: pending_review_payload
          }
        end

        private

        attr_reader :merchant

        def merchant_payload
          {
            id: merchant.id,
            name: merchant.name,
            platform_domain: merchant.platform_domain
          }
        end

        def stats_payload
          {
            variants_count: merchant.variants.active.count,
            pending_mappings_count: merchant.mapping_dictionaries.needs_attention.count,
            suppliers_count: merchant.suppliers.count
          }
        end

        def recent_activity_payload
          recent_uploads.map { |upload| activity_row(upload) }
        end

        def recent_uploads
          merchant.supplier_uploads
            .includes(:supplier)
            .where(status: RECENT_UPLOAD_STATUSES)
            .order(created_at: :desc)
            .limit(RECENT_UPLOAD_LIMIT)
        end

        def activity_row(upload)
          {
            id: upload.id,
            supplier_id: upload.supplier_id,
            supplier_name: upload.supplier.name,
            uploaded_at: upload.created_at.iso8601,
            resolved_count: upload.resolved_count,
            unresolved_count: upload.unresolved_count,
            status: activity_status(upload)
          }
        end

        def activity_status(upload)
          return "failed" if upload.status == "failed"
          return "warning" if upload.status.in?(%w[processing pending needs_review])

          "success"
        end

        def pending_review_payload
          count = merchant.mapping_dictionaries.needs_attention.count
          return { count: 0, supplier: nil } if count.zero?

          counts_by_supplier = merchant.mapping_dictionaries.needs_attention.group(:supplier_id).count
          supplier_id = counts_by_supplier.max_by { |_id, pending_count| pending_count }&.first

          supplier = merchant.suppliers.find_by(id: supplier_id)

          {
            count: count,
            supplier: supplier ? { id: supplier.id, name: supplier.name } : nil
          }
        end
      end
    end
  end
end
