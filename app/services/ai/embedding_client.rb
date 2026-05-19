# frozen_string_literal: true

require "faraday"
require "json"

module Ai
  class EmbeddingClient
    BASE_URL = "https://api.openai.com/v1"
    BATCH_SIZE = 100

    def self.embed_batch(texts)
      new.embed_batch(texts)
    end

    def embed_batch(texts)
      cleaned = texts.map { |text| text.to_s.strip }.reject(&:blank?)
      return [] if cleaned.empty?

      cleaned.each_slice(BATCH_SIZE).flat_map do |chunk|
        request_embeddings(chunk)
      end
    end

    private

    def request_embeddings(texts)
      raise "OpenAI API key is not configured" if Openai.api_key.blank?

      response = connection.post("embeddings") do |req|
        req.headers["Authorization"] = "Bearer #{Openai.api_key}"
        req.headers["Content-Type"] = "application/json"
        req.body = {
          model: Openai::EMBEDDING_MODEL,
          input: texts,
          dimensions: Openai::EMBEDDING_DIMENSIONS
        }.to_json
      end

      body = JSON.parse(response.body)
      unless response.success?
        message = body.dig("error", "message") || body.inspect
        raise "OpenAI embeddings API error: #{message}"
      end

      data = body["data"] || []
      ordered = data.sort_by { |row| row["index"] }
      ordered.map { |row| row["embedding"] }
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.options.timeout = 120
        f.options.open_timeout = 10
        f.adapter Faraday.default_adapter
      end
    end
  end
end
