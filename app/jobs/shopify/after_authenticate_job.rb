# frozen_string_literal: true

module Shopify
  # Runs after Shopify OAuth callback completes (via shopify_app PostAuthenticateTasks).
  class AfterAuthenticateJob < ApplicationJob
    queue_as :default

    def perform(shop_domain:)
      merchant = Merchant.find_by(platform_domain: shop_domain)
      return unless merchant

      CatalogSyncJob.perform_later(merchant.id)
    end
  end
end
