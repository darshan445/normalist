# frozen_string_literal: true

class DailyCatalogSyncJob < ApplicationJob
  queue_as :default

  def perform
    shopify_merchants = Merchant.where(platform: "shopify").where.not(access_token: nil)

    shopify_merchants.find_each do |merchant|
      CatalogSyncJob.perform_later(merchant.id)
    end

    Rails.logger.info(
      "[DailyCatalogSyncJob] enqueued sync for #{shopify_merchants.count} merchants"
    )
  end
end
