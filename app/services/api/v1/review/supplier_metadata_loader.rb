# frozen_string_literal: true

module Api
  module V1
    module Review
      class SupplierMetadataLoader
        def self.call(mappings:)
          new(mappings: mappings).call
        end

        def initialize(mappings:)
          @mappings = mappings
        end

        def call
          @mappings.each_with_object({}) do |mapping, result|
            result[mapping.id] = metadata_for(mapping)
          end
        end

        private

        def metadata_for(mapping)
          upload = mapping.supplier_upload
          profile = mapping.supplier.supplier_profile
          schema_map = profile&.file_schema_map || {}

          row = find_row(upload, mapping.supplier_code, profile)
          barcode = row&.dig("barcode") || row&.dig(:barcode)

          ProductMetadata.from_supplier_row(
            unique_code: mapping.supplier_code,
            barcode: barcode,
            raw_row: row&.dig("raw_row") || row&.dig(:raw_row),
            schema_map: schema_map
          )
        end

        def find_row(upload, supplier_code, profile)
          return nil unless upload&.file&.attached? && profile&.ready?

          cache = upload_cache[upload.id] ||= build_upload_index(upload, profile)
          cache[supplier_code]
        end

        def upload_cache
          @upload_cache ||= {}
        end

        def build_upload_index(upload, profile)
          rows = parse_upload_rows(upload, profile)
          rows.index_by { |row| row[:unique_code] }
        rescue StandardError => e
          Rails.logger.warn(
            "[SupplierMetadataLoader] upload=#{upload.id} error=#{e.message}"
          )
          {}
        end

        def parse_upload_rows(upload, profile)
          upload.file.open do |file|
            raw_rows = Ingestion::FileNormalizer.call(file, filename: upload.file.filename.to_s)
            Mapping::SchemaRowExtractor.call(raw_rows, profile.profile_hash)
          end
        end
      end
    end
  end
end
