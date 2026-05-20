# frozen_string_literal: true

module Mapping
  module Review
    class BulkReject
      Result = Data.define(:succeeded, :failed)

      def self.call(merchant:, supplier_id: nil, suggestion: "all")
        new(merchant: merchant, supplier_id: supplier_id, suggestion: suggestion).call
      end

      def initialize(merchant:, supplier_id:, suggestion:)
        @merchant = merchant
        @supplier_id = supplier_id.presence
        @suggestion = suggestion.presence || "all"
      end

      def call
        succeeded = 0
        failed = []

        review_scope.find_each do |mapping|
          Reject.call(merchant: @merchant, mapping_id: mapping.id)
          succeeded += 1
        rescue StandardError => e
          failed << { id: mapping.id, supplier_code: mapping.supplier_code, error: e.message }
        end

        Result.new(succeeded: succeeded, failed: failed)
      end

      private

      def review_scope
        scope = @merchant.mapping_dictionaries.review
        scope = scope.where(supplier_id: @supplier_id) if @supplier_id
        SuggestionScope.apply(scope, @suggestion)
      end
    end
  end
end
