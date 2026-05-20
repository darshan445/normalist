# frozen_string_literal: true

module Mapping
  module Review
    class MappingWriter
      def self.confirm!(mapping:, variant:)
        mapping.update!(
          status: "mapped",
          master_sku: variant.master_sku,
          platform_variant_id: variant.platform_variant_id,
          platform_inventory_id: variant.platform_inventory_id,
          last_seen: Time.current
        )
        mapping
      end

      def self.skip!(mapping:)
        mapping.update!(
          status: "skipped",
          pending_quantity: nil,
          last_seen: Time.current
        )
        mapping
      end
    end
  end
end
