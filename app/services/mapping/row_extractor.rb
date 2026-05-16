module Mapping
  class RowExtractor
    def self.call(rows, profile)
      sku_col = profile[:sku_column] || profile["sku_column"]
      qty_col = profile[:quantity_column] || profile["quantity_column"]

      rows.filter_map do |row|
        code = row[sku_col].to_s.strip
        next if code.blank?

        quantity = row[qty_col].to_s.strip
        quantity = quantity.to_i if quantity.match?(/\A-?\d+\z/)

        {
          supplier_code: code,
          quantity: quantity,
          raw_row: row
        }
      end
    end
  end
end
