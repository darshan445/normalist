# frozen_string_literal: true

module Mapping
  module Review
    class PendingQuantity
      def self.aggregate(quantities)
        values = Array(quantities).filter_map { |q| integer_value(q) }
        values.empty? ? nil : values.sum
      end

      def self.for_mapping(mapping)
        return [mapping.pending_quantity] if mapping.pending_quantity.present?

        QuantitiesForCode.call(
          supplier_upload: mapping.supplier_upload,
          supplier_code: mapping.supplier_code
        )
      end

      def self.resolved_row_count_for_mapping(mapping)
        upload = mapping.supplier_upload
        return 1 unless upload

        rows = Array(upload.output).select { |row| row["unique_code"] == mapping.supplier_code }
        count = rows.size
        count.positive? ? count : 1
      end

      def self.merge_on_mapping!(mapping, quantity)
        merged = aggregate([mapping.pending_quantity, quantity])
        return mapping if merged.nil?

        mapping.update!(pending_quantity: merged)
        mapping
      end

      def self.ensure_on_mapping!(mapping)
        return mapping if mapping.pending_quantity.present?

        merged = aggregate(for_mapping(mapping))
        return mapping if merged.nil?

        mapping.update!(pending_quantity: merged)
        mapping
      end

      def self.integer_value(value)
        return nil if value.blank?

        str = value.to_s.strip
        return nil unless str.match?(/\A-?\d+\z/)

        str.to_i
      end
      private_class_method :integer_value
    end
  end
end
