require "faraday"
require "json"

module Ai
  class GeminiClient
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"

    def self.generate_content(prompt)
      new.generate_content(prompt)
    end

    def generate_content(prompt)
      raise "Gemini API key is not configured" if Gemini.api_key.blank?

      response = connection.post("#{Gemini::MODEL}:generateContent") do |req|
        req.params["key"] = Gemini.api_key
        req.headers["Content-Type"] = "application/json"
        req.body = {
          contents: [
            { parts: [ { text: prompt } ] }
          ],
          generationConfig: {
            temperature: 0.1,
            responseMimeType: "application/json"
          }
        }.to_json
      end

      body = JSON.parse(response.body)
      raise "Gemini API error: #{body}" unless response.success?

      text = body.dig("candidates", 0, "content", "parts", 0, "text")
      raise "Empty Gemini response" if text.blank?

      JSON.parse(text)
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.options.timeout = 30
        f.options.open_timeout = 10
        f.adapter Faraday.default_adapter
      end
    end
  end
end
