# frozen_string_literal: true

module Mapping
  class UnmatchedDeduplicator
    Result = Data.define(:quantities_by_code, :unique_codes)

    def self.call(unmatched_rows)
      new(unmatched_rows).call
    end

    def initialize(unmatched_rows)
      @unmatched_rows = unmatched_rows
    end

    def call
      quantities_by_code = Hash.new { |hash, key| hash[key] = [] }

      @unmatched_rows.each do |row|
        code = row["unique_code"] || row[:unique_code]
        next if code.blank?

        quantities_by_code[code] << row["quantity"] || row[:quantity]
      end

      Result.new(
        quantities_by_code: quantities_by_code,
        unique_codes: quantities_by_code.keys
      )
    end
  end
end
