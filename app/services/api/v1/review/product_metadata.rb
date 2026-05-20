# frozen_string_literal: true

module Api
  module V1
    module Review
      class ProductMetadata
        def self.from_variant(variant)
          return nil unless variant

          fields = {
            product: variant.product_title.presence,
            variant: variant.variant_title.presence,
            title: variant.product_title.presence,
            size: nil,
            color: nil
          }.merge(parse_variant_title(variant.variant_title))

          fields[:title] ||= fields[:product]

          build_payload(
            unique_code: variant.master_sku,
            barcode: variant.barcode.presence,
            fields: fields
          )
        end

        def self.from_supplier_row(unique_code:, barcode:, raw_row:, schema_map:)
          fields = extract_supplier_fields(raw_row, schema_map)

          build_payload(
            unique_code: unique_code,
            barcode: barcode.presence,
            fields: fields
          )
        end

        def self.parse_variant_title(variant_title)
          return {} if variant_title.blank?

          segments = variant_title.split(/\s*\/\s*/).map(&:strip).reject(&:blank?)
          return { variant: variant_title } if segments.size < 2

          {
            color: segments[0],
            size: segments[1..].join(" / ")
          }
        end

        def self.extract_supplier_fields(raw_row, schema_map)
          return {} if raw_row.blank?

          attributes = schema_map.fetch("supplier_attributes", {})
          {
            product: cell(raw_row, attributes["product"]),
            variant: cell(raw_row, attributes["variant"]),
            title: cell(raw_row, attributes["title"]),
            size: cell(raw_row, attributes["size"]),
            color: cell(raw_row, attributes["color"])
          }.compact
        end

        def self.cell(row, column)
          return if column.blank?

          row[column].to_s.strip.presence
        end

        def self.build_payload(unique_code:, barcode:, fields:)
          {
            unique_code: unique_code,
            barcode: barcode,
            product: fields[:product],
            variant: fields[:variant],
            title: fields[:title],
            size: fields[:size],
            color: fields[:color],
            metadata: format_metadata(fields)
          }
        end

        def self.format_metadata(fields)
          parts = []
          parts << "Product: #{fields[:product]}" if fields[:product].present?
          parts << "Variant: #{fields[:variant]}" if fields[:variant].present?
          parts << "Title: #{fields[:title]}" if fields[:title].present?
          parts << "Size: #{fields[:size]}" if fields[:size].present?
          parts << "Color: #{fields[:color]}" if fields[:color].present?
          parts.join(" · ")
        end

        private_class_method :parse_variant_title, :extract_supplier_fields, :cell, :build_payload, :format_metadata
      end
    end
  end
end
