# frozen_string_literal: true

module Api
  module V1
    module Suppliers
      class BuildMappingsIndex
        DEFAULT_PER_PAGE = 50
        MAX_PER_PAGE = 100
        ALLOWED_STATUSES = %w[mapped pending skipped review all].freeze

        def self.call(supplier:, page: 1, per_page: DEFAULT_PER_PAGE, status: "all")
          new(supplier:, page:, per_page:, status:).call
        end

        def initialize(supplier:, page:, per_page:, status:)
          @supplier = supplier
          @page = [ page.to_i, 1 ].max
          @per_page = per_page.to_i.clamp(1, MAX_PER_PAGE)
          @status = ALLOWED_STATUSES.include?(status.to_s) ? status.to_s : "all"
        end

        def call
          scope = base_scope
          total_count = scope.count
          rows = scope.offset(offset).limit(@per_page)

          {
            supplier: { id: @supplier.id, name: @supplier.name },
            status_filter: @status,
            mappings: rows.map { |row| mapping_row(row) },
            pagination: {
              page: @page,
              per_page: @per_page,
              total_count: total_count,
              total_pages: total_pages(total_count)
            }
          }
        end

        private

        def base_scope
          scope = @supplier.mapping_dictionaries.order(:supplier_code)
          return scope if @status == "all"

          scope.where(status: @status)
        end

        def offset
          (@page - 1) * @per_page
        end

        def total_pages(total_count)
          return 0 if total_count.zero?

          (total_count.to_f / @per_page).ceil
        end

        def mapping_row(row)
          {
            id: row.id,
            supplier_code: row.supplier_code,
            master_sku: row.master_sku,
            status: row.status,
            last_seen: row.last_seen&.iso8601
          }
        end
      end
    end
  end
end
