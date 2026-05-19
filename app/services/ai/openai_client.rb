# frozen_string_literal: true

require "faraday"
require "json"

module Ai
  class OpenaiClient
    BASE_URL = "https://api.openai.com/v1"

    def self.chat_json(system_prompt:, user_prompt:)
      new.chat_json(system_prompt: system_prompt, user_prompt: user_prompt)
    end

    def chat_json(system_prompt:, user_prompt:)
      raise "OpenAI API key is not configured" if Openai.api_key.blank?

      response = connection.post("chat/completions") do |req|
        req.headers["Authorization"] = "Bearer #{Openai.api_key}"
        req.headers["Content-Type"] = "application/json"
        req.body = {
          model: Openai::MODEL,
          temperature: 0.1,
          response_format: { type: "json_object" },
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: user_prompt }
          ]
        }.to_json
      end

      body = JSON.parse(response.body)
      unless response.success?
        message = body.dig("error", "message") || body.inspect
        raise "OpenAI API error: #{message}"
      end

      content = body.dig("choices", 0, "message", "content")
      raise "Empty OpenAI response" if content.blank?

      JSON.parse(content)
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.options.timeout = 60
        f.options.open_timeout = 10
        f.adapter Faraday.default_adapter
      end
    end
  end
end
