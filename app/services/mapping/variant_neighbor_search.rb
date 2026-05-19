# frozen_string_literal: true

module Mapping
  class VariantNeighborSearch
    LIMIT = 5

    Candidate = Data.define(:variant, :distance)

    def self.call(merchant:, vector:)
      new(merchant: merchant, vector: vector).call
    end

    def initialize(merchant:, vector:)
      @merchant = merchant
      @vector = vector
    end

    def call
      return [] if @vector.blank?

      Variant
        .where(merchant_id: @merchant.id)
        .active
        .where.not(embedding: nil)
        .nearest_neighbors(:embedding, @vector, distance: "cosine")
        .limit(LIMIT)
        .map { |variant| Candidate.new(variant: variant, distance: variant.neighbor_distance.to_f) }
    end
  end
end
