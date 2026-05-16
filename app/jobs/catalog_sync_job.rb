# frozen_string_literal: true

class CatalogSyncJob < ApplicationJob
  queue_as :catalog

  def perform(merchant_id:)
    merchant = Merchant.find(merchant_id)
    Rails.logger.info("[CatalogSyncJob] placeholder queued for merchant #{merchant.id} (#{merchant.platform_domain})")
  end
end
