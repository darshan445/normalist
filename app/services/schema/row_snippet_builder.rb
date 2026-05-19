# frozen_string_literal: true

module Schema
  class RowSnippetBuilder
    MAX_SAMPLE_ROWS = 5

    def self.call(rows:, max_rows: MAX_SAMPLE_ROWS)
      new(rows: rows, max_rows: max_rows).call
    end

    def initialize(rows:, max_rows:)
      @rows = rows
      @max_rows = max_rows
    end

    # Builds a column-oriented payload for the AI: each header with sample
    # values taken from the most informative data rows in the file.
    def call
      data_rows = @rows.reject { |row| empty_row?(row) }
      return { "columns" => [] } if data_rows.empty?

      sample_rows = select_representative_rows(data_rows, @max_rows)
      headers = sample_rows.first.keys

      {
        "columns" => headers.map { |header| column_payload(header, sample_rows) }
      }
    end

    private

    def select_representative_rows(rows, limit)
      rows
        .sort_by { |row| -filled_cell_count(row) }
        .first(limit)
        .sort_by { |row| rows.index(row) }
    end

    def column_payload(header, sample_rows)
      values = sample_rows.map { |row| row[header] }.map { |value| sanitize_value(value) }

      {
        "header" => header,
        "sample_values" => values
      }
    end

    def filled_cell_count(row)
      row.values.count(&:present?)
    end

    def empty_row?(row)
      row.values.all?(&:blank?)
    end

    def sanitize_value(value)
      return nil if value.nil?

      value.to_s.strip.presence
    end
  end
end
