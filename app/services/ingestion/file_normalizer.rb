# frozen_string_literal: true

module Ingestion
  class FileNormalizer
    PRINTABLE_PATTERN = /[^\x20-\x7E\t]/

    def self.call(io_or_path, filename: nil)
      new(io_or_path, filename: filename).call
    end

    def initialize(io_or_path, filename: nil)
      @io_or_path = io_or_path
      @filename = filename
    end

    def call
      rows = FileParser.call(@io_or_path, filename: @filename)
      normalize_rows(rows)
    end

    private

    def normalize_rows(rows)
      cleaned = rows.map { |row| sanitize_row(row) }.reject { |row| empty_row?(row) }
      strip_edge_blank_rows(cleaned)
    end

    def strip_edge_blank_rows(rows)
      rows.drop_while { |row| empty_row?(row) }
          .reverse
          .drop_while { |row| empty_row?(row) }
          .reverse
    end

    def sanitize_row(row)
      row.transform_keys { |key| sanitize_text(key) }
           .transform_values { |value| sanitize_cell(value) }
    end

    def sanitize_cell(value)
      return nil if value.nil?

      text = sanitize_text(value.to_s)
      text.presence
    end

    def sanitize_text(text)
      text.gsub(PRINTABLE_PATTERN, "").strip
    end

    def empty_row?(row)
      row.values.all?(&:blank?)
    end
  end
end
