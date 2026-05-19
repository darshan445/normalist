# frozen_string_literal: true

module Openai
  MODEL = ENV.fetch("OPENAI_MODEL", "gpt-4o-mini")
  EMBEDDING_MODEL = ENV.fetch("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small")
  EMBEDDING_DIMENSIONS = 1536

  def self.api_key
    ENV["OPENAI_API_KEY"]
  end
end
