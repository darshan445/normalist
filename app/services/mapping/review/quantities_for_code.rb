# frozen_string_literal: true

module Mapping
  module Review
    class QuantitiesForCode
      def self.call(supplier_upload:, supplier_code:)
        new(supplier_upload: supplier_upload, supplier_code: supplier_code).call
      end

      def initialize(supplier_upload:, supplier_code:)
        @supplier_upload = supplier_upload
        @supplier_code = supplier_code
      end

      def call
        rows = output_rows
        return [ nil ] if rows.empty?

        rows.map { |row| row["quantity"] }
      end

      private

      def output_rows
        return [] unless @supplier_upload

        Array(@supplier_upload.output).select { |row| row["unique_code"] == @supplier_code }
      end
    end
  end
end
