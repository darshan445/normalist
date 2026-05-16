# frozen_string_literal: true

module Gemini
  MODEL = ENV.fetch("GEMINI_MODEL", "gemini-2.5-flash")

  def self.api_key
    ENV.fetch("GEMINI_API_KEY")
  end
end
