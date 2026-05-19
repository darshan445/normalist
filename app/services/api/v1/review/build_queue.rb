# frozen_string_literal: true

module Api
  module V1
    module Review
      class BuildQueue
        DEFAULT_PER_PAGE = 25
        MAX_PER_PAGE = 100

        def self.call(merchant:, page: 1, per_page: DEFAULT_PER_PAGE, supplier_id: nil)
          new(merchant: merchant, page: page, per_page: per_page, supplier_id: supplier_id).call
        end

        def initialize(merchant:, page:, per_page:, supplier_id: nil)
          @merchant = merchant
          @page = [ page.to_i, 1 ].max
          @per_page = per_page.to_i.clamp(1, MAX_PER_PAGE)
          @supplier_id = supplier_id.presence
        end

        def call
          scope = base_scope
          total_count = scope.count
          mappings = scope.offset(offset).limit(@per_page).to_a
          variants_by_platform = load_variants(mappings)

          {
            items: mappings.map { |mapping| queue_item(mapping, variants_by_platform) },
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
          scope = @merchant.mapping_dictionaries
                           .review
                           .includes(:supplier, :supplier_upload)
                           .order(created_at: :desc)
          scope = scope.where(supplier_id: @supplier_id) if @supplier_id
          scope
        end

        def offset
          (@page - 1) * @per_page
        end

        def total_pages(total_count)
          return 0 if total_count.zero?

          (total_count.to_f / @per_page).ceil
        end

        def load_variants(mappings)
          platform_ids = mappings.filter_map(&:platform_variant_id).uniq
          return {} if platform_ids.empty?

          @merchant.variants.active
                  .where(platform_variant_id: platform_ids)
                  .index_by(&:platform_variant_id)
        end

        def queue_item(mapping, variants_by_platform)
          variant = suggested_variant(mapping, variants_by_platform)

          {
            id: mapping.id,
            supplier_code: mapping.supplier_code,
            confidence: mapping.confidence_score,
            created_at: mapping.created_at.iso8601,
            supplier: {
              id: mapping.supplier_id,
              name: mapping.supplier.name
            },
            suggested_variant: variant_payload(variant),
            supplier_upload: upload_payload(mapping)
          }
        end

        def suggested_variant(mapping, variants_by_platform)
          if mapping.platform_variant_id.present?
            variants_by_platform[mapping.platform_variant_id] ||
              @merchant.variants.active.find_by(platform_variant_id: mapping.platform_variant_id)
          elsif mapping.master_sku.present?
            @merchant.variants.active.find_by(master_sku: mapping.master_sku)
          end
        end

        def variant_payload(variant)
          return nil unless variant

          {
            id: variant.id,
            product_title: variant.product_title,
            variant_title: variant.variant_title,
            master_sku: variant.master_sku,
            barcode: variant.barcode
          }
        end

        def upload_payload(mapping)
          upload = mapping.supplier_upload
          return nil unless upload

          rows = Mapping::Review::QuantitiesForCode.call(
            supplier_upload: upload,
            supplier_code: mapping.supplier_code
          )

          {
            id: upload.id,
            status: upload.status,
            stage: upload.stage,
            resolved_count: upload.resolved_count,
            unresolved_count: upload.unresolved_count,
            created_at: upload.created_at.iso8601,
            quantities: rows
          }
        end
      end
    end
  end
end
