# frozen_string_literal: true

module Schema
  class Discovery
    Result = Data.define(:outcome, :stage, :error_message, :row_count, :profile_stage) do
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
        discover_and_persist!(headers, rows.size, rows)
      else
        refresh_existing_profile!(headers, rows.size, rows)
      end
    rescue StandardError => e
      failed(e.message)
    end

    private

    def completed(stage, row_count:, profile_stage:)
      Result.new(
        outcome: :completed,
        stage: stage,
        error_message: nil,
        row_count: row_count,
        profile_stage: profile_stage
      )
    end

    def failed(message)
      Result.new(
        outcome: :failed,
        stage: "failed",
        error_message: message,
        row_count: nil,
        profile_stage: nil
      )
    end

    def parse_normalized_rows
      unless @upload.file.attached?
        Rails.logger.warn("[Schema::Discovery] Upload #{@upload.id} has no file attached")
        return []
      end

      content = Ingestion::UploadFileContent.call(@upload)
      return [] if content.blank?

      Ingestion::FileNormalizer.call(content, filename: @upload.file.filename.to_s)
    rescue ActiveStorage::FileNotFoundError, ArgumentError, StandardError => e
      Rails.logger.error("[Schema::Discovery] Failed to parse upload #{@upload.id}: #{e.class} — #{e.message}")
      []
    end

    def needs_discovery?(headers)
      LayoutDriftDetector.call(supplier: @supplier, incoming_headers: headers)
    end

    def discover_and_persist!(headers, row_count, rows)
      mapping = AiSchemaScanner.call(rows: rows)
      persist_schema_map!(headers, mapping)
      completed("Column schema discovered", row_count: row_count, profile_stage: "ai_detection")
    end

    def refresh_existing_profile!(headers, row_count, rows)
      profile = @supplier.supplier_profile || find_or_build_profile

      unless profile.ready?
        return discover_and_persist!(headers, row_count, rows)
      end

      profile.refresh_from_upload!(headers: headers)
      completed(
        "Column layout unchanged — existing schema kept",
        row_count: row_count,
        profile_stage: "profile_cache"
      )
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
