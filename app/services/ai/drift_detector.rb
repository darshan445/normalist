module Ai
  class DriftDetector
    def self.call(supplier_profile, incoming_headers)
      new(supplier_profile, incoming_headers).call
    end

    def initialize(supplier_profile, incoming_headers)
      @profile = supplier_profile
      @incoming_headers = normalize_headers(incoming_headers)
    end

    # Returns true when cached profile headers no longer match the file.
    def call
      return true if @profile.blank?

      stored = normalize_headers(@profile.raw_headers)
      stored != @incoming_headers
    end

    private

    def normalize_headers(headers)
      Array(headers).map { |h| h.to_s.strip }
    end
  end
end
