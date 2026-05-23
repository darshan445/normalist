# frozen_string_literal: true

module Mapping
  module UniqueCodeCounts
    module_function

    def from_supplier_codes(codes)
      codes.filter_map { |code| code.presence }.uniq
    end

    def partition(resolved_rows, unresolved_rows)
      resolved_codes = from_supplier_codes(
        resolved_rows.map { |row| supplier_code_from(row) }
      )
      unresolved_codes = from_supplier_codes(
        unresolved_rows.map { |row| supplier_code_from(row) }
      ) - resolved_codes

      {
        unique_code_count: (resolved_codes + unresolved_codes).size,
        resolved_count: resolved_codes.size,
        unresolved_count: unresolved_codes.size
      }
    end

    def supplier_code_from(row)
      return row.supplier_code if row.respond_to?(:supplier_code)

      row[:supplier_code] || row["supplier_code"]
    end
  end
end
