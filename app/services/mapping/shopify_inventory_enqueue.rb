# frozen_string_literal: true

module Mapping
  class ShopifyInventoryEnqueue
    def self.call(mapping:)
      mapping = mapping.reload if mapping.persisted?
      return unless mapping.status == "mapped"
      return if mapping.pending_quantity.blank?

      Shopify::InventoryUpdateJob.perform_later(
        mapping.merchant_id,
        mapping.supplier_upload_id,
        mapping.id
      )
    end
  end
end
