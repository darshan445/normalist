# frozen_string_literal: true

module Api
  module V1
    module Suppliers
      class Serialize
        def self.call(supplier, mapped_count: nil, pending_count: nil)
          mapped = mapped_count.nil? ? count_for(supplier, "mapped") : mapped_count
          pending = pending_count.nil? ? count_for(supplier, "pending") : pending_count

          {
            id: supplier.id,
            name: supplier.name,
            mapped_count: mapped,
            pending_count: pending,
            status: pending.positive? ? "warning" : "ok"
          }
        end

        def self.count_for(supplier, status)
          supplier.mapping_dictionaries.where(status:).count
        end
      end
    end
  end
end
