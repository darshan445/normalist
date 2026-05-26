# frozen_string_literal: true

module Shopify
  # Runs after Shopify OAuth callback completes (via shopify_app PostAuthenticateTasks).
  class AfterAuthenticateJob < ApplicationJob
    queue_as :default

    def perform(shop_domain:)
      merchant = Merchant.find_by(platform_domain: shop_domain)
      return unless merchant

      Shopify::MigrateExpiringToken.call(merchant: merchant)

      if merchant.trial_starts_at.nil?
        merchant.update!(
          trial_starts_at: Time.current,
          trial_ends_at: 14.days.from_now,
          plan_status: "trialing"
        )

        Billing::PlanChangeRecorder.call(
          merchant: merchant,
          to_plan: "trial",
          reason: "install",
          initiated_by: "system"
        )

        Rails.logger.info(
          "[AfterAuthenticateJob] trial started " \
          "merchant=#{merchant.id} " \
          "ends_at=#{merchant.trial_ends_at}"
        )
      end

      Shopify::RegisterWebhooks.call(shop_domain: merchant.platform_domain)

      CatalogSyncJob.perform_later(merchant.id)
    end
  end
end
