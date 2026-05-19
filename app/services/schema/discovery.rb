# frozen_string_literal: true

module Schema
  class Discovery
    Result = Data.define(:outcome, :stage, :error_message) do
      def success?
        outcome == :completed
      end

      def failure?
        outcome == :failed
      end
    end

    def self.call(upload:)
      new(upload: upload).call
    end

    def initialize(upload:)
      @upload = upload
      @supplier = upload.supplier
      @merchant = upload.merchant
    end

    def call
      rows = parse_normalized_rows
      return failed("No file attached or file could not be parsed") if rows.blank?

      headers = rows.first.keys

      if needs_discovery?(headers)
        discover_and_persist!(headers, rows)
      else
        refresh_existing_profile!(headers, rows)
      end
    rescue StandardError => e
      failed(e.message)
    end

    private

    def completed(stage)
      Result.new(outcome: :completed, stage: stage, error_message: nil)
    end

    def failed(message)
      Result.new(outcome: :failed, stage: "Failed", error_message: message)
    end

    def parse_normalized_rows
      unless @upload.file.attached?
        Rails.logger.warn("[Schema::Discovery] Upload #{@upload.id} has no file attached")
        return []
      end

      @upload.file.open do |file|
        Ingestion::FileNormalizer.call(file, filename: @upload.file.filename.to_s)
      end
    rescue ArgumentError, StandardError => e
      Rails.logger.error("[Schema::Discovery] Failed to parse upload #{@upload.id}: #{e.message}")
      []
    end

    def needs_discovery?(headers)
      LayoutDriftDetector.call(supplier: @supplier, incoming_headers: headers)
    end

    def discover_and_persist!(headers, rows)
      mapping = AiSchemaScanner.call(rows: rows)
      persist_schema_map!(headers, mapping)
      completed("Column schema discovered")
    end

    def refresh_existing_profile!(headers, rows)
      profile = @supplier.supplier_profile || find_or_build_profile

      unless profile.ready?
        return discover_and_persist!(headers, rows)
      end

      profile.refresh_from_upload!(headers: headers)
      completed("Column layout unchanged — existing schema kept")
    end

    def persist_schema_map!(headers, mapping)
      profile = find_or_build_profile
      profile.apply_schema_discovery!(headers: headers, mapping: mapping)
    end

    def find_or_build_profile
      SupplierProfile.find_or_initialize_by(merchant: @merchant, supplier: @supplier)
    end
  end
end
