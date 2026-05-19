# frozen_string_literal: true

module Mapping
  class AiMatchConfirmer
    BATCH_SIZE = 50

    Decision = Data.define(:supplier_code, :variant_id, :confident)

    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are matching supplier product codes to a merchant's Shopify catalog variants.

      For each supplier code, choose the single best matching variant from the candidates,
      or return null for variant_id if none are a good match.

      Respond ONLY with valid JSON using this schema:
      {
        "matches": [
          { "supplier_code": "string", "variant_id": "uuid string or null", "confident": true }
        ]
      }

      Set confident to true only when you are sure of the match. Otherwise set confident to false.
    PROMPT

    def self.call(entries:)
      new(entries: entries).call
    end

    def initialize(entries:)
      @entries = entries
    end

    def call
      return [] if @entries.empty?

      @entries.each_slice(BATCH_SIZE).flat_map do |batch|
        parse_batch(batch)
      end
    end

    private

    def parse_batch(batch)
      response = Ai::OpenaiClient.chat_json(
        system_prompt: SYSTEM_PROMPT,
        user_prompt: build_user_prompt(batch)
      )

      matches = response["matches"] || []
      matches.map do |match|
        Decision.new(
          supplier_code: match["supplier_code"].to_s,
          variant_id: match["variant_id"].presence,
          confident: match["confident"] == true
        )
      end
    end

    def build_user_prompt(batch)
      lines = batch.map { |entry| format_entry(entry) }

      <<~PROMPT
        Supplier codes and candidates:
        #{lines.join("\n")}
      PROMPT
    end

    def format_entry(entry)
      candidates = entry[:candidates].map do |candidate|
        variant = candidate.variant
        "#{variant.product_title} / #{variant.variant_title} (sku: #{variant.master_sku}, id: #{variant.id})"
      end

      "- #{entry[:supplier_code]} → candidates: [#{candidates.join('; ')}]"
    end
  end
end
