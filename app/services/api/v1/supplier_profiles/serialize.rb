# frozen_string_literal: true

module Api
  module V1
    module SupplierProfiles
      class Serialize
        def self.call(profile)
          return nil unless profile&.ready?

          {
            sku_column_name: profile.unique_column,
            quantity_column_name: profile.quantity_column,
            barcode_column_name: profile.barcode_column,
            last_used_at: profile.last_used_at&.iso8601,
            cached: true
          }
        end
      end
    end
  end
end
