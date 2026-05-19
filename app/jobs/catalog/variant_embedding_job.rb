# frozen_string_literal: true

module Catalog
  class VariantEmbeddingJob < ApplicationJob
    queue_as :catalog

    def perform(merchant_id, variant_ids: nil)
      merchant = Merchant.find(merchant_id)
      variants = variant_ids.present? ? merchant.variants.where(id: variant_ids) : nil
      VariantEmbedder.call(merchant: merchant, variants: variants)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("[Catalog::VariantEmbeddingJob] Merchant #{merchant_id} not found")
    rescue StandardError => e
      Rails.logger.error(
        "[Catalog::VariantEmbeddingJob] Failed for merchant #{merchant_id}: #{e.class} — #{e.message}"
      )
      raise
    end
  end
end
