# frozen_string_literal: true

module Mapping
  module Review
    class FindReviewMapping
      class NotFound < StandardError; end
      class NotReviewable < StandardError; end

      def self.call(merchant:, mapping_id:)
        new(merchant: merchant, mapping_id: mapping_id).call
      end

      def initialize(merchant:, mapping_id:)
        @merchant = merchant
        @mapping_id = mapping_id
      end

      def call
        mapping = @merchant.mapping_dictionaries.find(@mapping_id)
        raise NotReviewable, "Mapping is not awaiting review" unless mapping.status == "review"

        mapping
      rescue ActiveRecord::RecordNotFound
        raise NotFound, "Review item not found"
      end
    end
  end
end
