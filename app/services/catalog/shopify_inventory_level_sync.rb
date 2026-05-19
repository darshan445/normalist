# frozen_string_literal: true

module Catalog
  class ShopifyInventoryLevelSync
    def self.call(merchant:, level:)
      new(merchant: merchant, level: level).call
    end

    def initialize(merchant:, level:)
      @merchant = merchant
      @level = level
    end

    def call
      return false unless relevant_location?

      variant = @merchant.variants.find_by(
        platform_inventory_id: @level["inventory_item_id"].to_s
      )
      return false unless variant

      variant.update!(synced_at: Time.current)

      Rails.logger.info(
        "[Catalog::ShopifyInventoryLevelSync] merchant=#{@merchant.id} " \
        "variant=#{variant.id} location=#{@level['location_id']} " \
        "available=#{@level['available']}"
      )

      true
    end

    private

    def relevant_location?
      return true if @merchant.location_id.blank?

      @merchant.location_id == @level["location_id"].to_s
    end
  end
end
