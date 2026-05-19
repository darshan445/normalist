# frozen_string_literal: true

module Mapping
  class SchemaRowExtractor
    def self.call(rows, profile)
      new(rows, profile).call
    end

    def initialize(rows, profile)
      @rows = rows
      @profile = profile
    end

    def call
      unique_col = column_name(:unique_column, fallback: :sku_column)
      quantity_col = column_name(:quantity_column)
      barcode_col = @profile[:barcode_column] || @profile["barcode_column"]

      @rows.filter_map do |row|
        unique_value = cell_value(row, unique_col)
        next if unique_value.blank?

        {
          unique_code: unique_value,
          barcode: barcode_col.present? ? cell_value(row, barcode_col) : nil,
          quantity: parse_quantity(cell_value(row, quantity_col)),
          raw_row: row
        }
      end
    end

    private

    def column_name(key, fallback: nil)
      @profile[key] || @profile[key.to_s] || (fallback && (@profile[fallback] || @profile[fallback.to_s]))
    end

    def cell_value(row, column)
      row[column].to_s.strip
    end

    def parse_quantity(value)
      return value if value.blank?

      string = value.to_s.strip
      return string.to_i if string.match?(/\A-?\d+\z/)

      string
    end
  end
end
