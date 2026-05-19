# frozen_string_literal: true

module Schema
  class LayoutDriftDetector
    def self.call(supplier:, incoming_headers:)
      new(supplier: supplier, incoming_headers: incoming_headers).call
    end

    def initialize(supplier:, incoming_headers:)
      @supplier = supplier
      @incoming_headers = normalize_headers(incoming_headers)
    end

    # Returns true when the file layout no longer matches the saved profile.
    def call
      profile = @supplier.supplier_profile
      return true if profile.blank?

      stored = normalize_headers(profile.raw_headers)
      return true if stored.blank?

      stored != @incoming_headers
    end

    private

    def normalize_headers(headers)
      Array(headers).map { |header| header.to_s.strip }
    end
  end
end
