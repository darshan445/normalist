# frozen_string_literal: true

module Catalog
  class VariantEmbedder
    BATCH_SIZE = 100

    def self.call(merchant:)
      new(merchant: merchant).call
    end

    def initialize(merchant:)
      @merchant = merchant
    end

    def call
      scope = @merchant.variants.active
      total = 0

      scope.find_in_batches(batch_size: BATCH_SIZE) do |variants|
        embed_variants!(variants)
        total += variants.size
      end

      Rails.logger.info(
        "[Catalog::VariantEmbedder] merchant=#{@merchant.id} embedded=#{total} variants"
      )

      total
    end

    private

    def embed_variants!(variants)
      pairs = variants.filter_map do |variant|
        text = variant.embedding_text
        next if text.blank?

        [variant, text]
      end

      return if pairs.empty?

      texts = pairs.map(&:last)
      vectors = Ai::EmbeddingClient.embed_batch(texts)
      timestamp = Time.current

      pairs.each_with_index do |(variant, _text), index|
        variant.update_columns(
          embedding: vectors[index],
          embedded_at: timestamp,
          updated_at: timestamp
        )
      end
    end
  end
end
