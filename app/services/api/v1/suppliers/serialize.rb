# frozen_string_literal: true

module Api
  module V1
    module Suppliers
      class Serialize
        def self.call(supplier, mapped_count: nil, pending_count: nil, skipped_count: nil, review_count: nil)
          mapped = mapped_count.nil? ? count_for(supplier, "mapped") : mapped_count
          pending = pending_count.nil? ? count_for(supplier, "pending") : pending_count
          skipped = skipped_count.nil? ? count_for(supplier, "skipped") : skipped_count
          review = review_count.nil? ? count_for(supplier, "review") : review_count

          {
            id: supplier.id,
            name: supplier.name,
            mapped_count: mapped,
            pending_count: pending,
            skipped_count: skipped,
            review_count: review,
            needs_attention_count: pending + review,
            status: (pending + review).positive? ? "warning" : "ok"
          }
        end

        def self.count_for(supplier, status)
          supplier.mapping_dictionaries.where(status:).count
        end
      end
    end
  end
end
