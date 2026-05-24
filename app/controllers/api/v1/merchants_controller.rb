# frozen_string_literal: true

module Api
  module V1
    class MerchantsController < BaseController
      skip_before_action :check_billing_access, only: :trial_status

      def trial_status
        merchant = current_merchant
        sub = merchant.active_subscription

        render json: {
          plan_status: merchant.plan_status,
          has_access: merchant.has_access?,
          trialing: merchant.trialing?,
          trial_expired: merchant.trial_expired?,
          trial_ending_soon: merchant.trial_ending_soon?,
          trial_days_remaining: merchant.trial_days_remaining,
          trial_ends_at: merchant.trial_ends_at,
          subscribed: merchant.subscribed?,
          billing_on: sub&.billing_on,
          price: sub&.price
        }
      end

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
