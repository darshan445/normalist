# frozen_string_literal: true

module Api
  module V1
    class MerchantsController < BaseController
      def catalog_sync_status
        merchant = current_merchant

        render json: {
          catalog_synced_at: merchant.catalog_synced_at,
          location_id: merchant.location_id,
          total_variants: Variant.for_merchant(merchant.id).count,
          no_sku_variants: Variant.for_merchant(merchant.id).needs_sku.count,
          platform: merchant.platform
        }
      end
    end
  end
end
