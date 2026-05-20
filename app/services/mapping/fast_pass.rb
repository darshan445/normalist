# frozen_string_literal: true

module Mapping
  class FastPass
    Result = Data.define(:resolved_count, :unresolved_count, :unmatched_rows, :stage_message)

    def self.call(upload:)
      new(upload: upload).call
    end

    def initialize(upload:)
      @upload = upload
      @merchant = upload.merchant
      @supplier = upload.supplier
    end

    def call
      profile = @supplier.supplier_profile
      raise "Supplier profile is not ready" unless profile&.ready?

      rows = parse_rows
      return empty_result("No rows to process") if rows.empty?

      @mapped_by_code = load_mapped_dictionary
      @resolved_count = 0
      @unresolved_count = 0
      @unmatched_rows = []

      rows.each { |row| process_row(row) }

      Result.new(
        resolved_count: @resolved_count,
        unresolved_count: @unresolved_count,
        unmatched_rows: @unmatched_rows,
        stage_message: completion_message
      )
    end

    private

    def parse_rows
      unless @upload.file.attached?
        Rails.logger.warn("[Mapping::FastPass] Upload #{@upload.id} has no file attached")
        return []
      end

      profile_columns = @supplier.supplier_profile.profile_hash

      @upload.file.open do |file|
        raw_rows = Ingestion::FileNormalizer.call(file, filename: @upload.file.filename.to_s)
        SchemaRowExtractor.call(raw_rows, profile_columns)
      end
    rescue ArgumentError, StandardError => e
      Rails.logger.error("[Mapping::FastPass] Failed to parse upload #{@upload.id}: #{e.message}")
      []
    end

    def load_mapped_dictionary
      @merchant.mapping_dictionaries
              .mapped
              .where(supplier: @supplier)
              .index_by(&:supplier_code)
    end

    def process_row(row)
      mapping = find_mapped_dictionary(row[:unique_code])
      mapping ||= find_mapped_dictionary(row[:barcode]) if row[:barcode].present?

      if mapping
        resolve_from_dictionary!(row, mapping)
        return
      end

      variant = find_variant(row[:unique_code])
      variant ||= find_variant(row[:barcode]) if row[:barcode].present?

      if variant
        mapping = create_review_mapping!(row, variant)
        resolve_from_dictionary!(row, mapping)
        return
      end

      collect_unmatched!(row)
    end

    def find_mapped_dictionary(supplier_code)
      return if supplier_code.blank?

      @mapped_by_code[supplier_code]
    end

    def resolve_from_dictionary!(row, mapping)
      Review::PendingQuantity.merge_on_mapping!(mapping, row[:quantity])
      mapping.update!(supplier_upload_id: @upload.id) if mapping.supplier_upload_id.blank?
      mapping.touch_last_seen!
      @resolved_count += 1

      ShopifyInventoryEnqueue.call(mapping: mapping)
    end

    def find_variant(value)
      return if value.blank?

      @merchant.variants.active.find_by(master_sku: value) ||
        @merchant.variants.active.find_by(barcode: value)
    end

    def create_review_mapping!(row, variant)
      mapping = @merchant.mapping_dictionaries.find_or_initialize_by(
        supplier: @supplier,
        supplier_code: row[:unique_code]
      )

      mapping.assign_attributes(
        master_sku: variant.master_sku,
        platform_variant_id: variant.platform_variant_id,
        platform_inventory_id: variant.platform_inventory_id,
        status: "mapped",
        supplier_upload_id: @upload.id,
        last_seen: Time.current
      )
      mapping.save!
      mapping
    end

    def collect_unmatched!(row)
      @unresolved_count += 1
      @unmatched_rows << {
        "unique_code" => row[:unique_code],
        "barcode" => row[:barcode],
        "quantity" => row[:quantity],
        "raw_row" => row[:raw_row]
      }
    end

    def completion_message
      parts = []
      parts << "#{@resolved_count} resolved" if @resolved_count.positive?
      parts << "#{@unresolved_count} need attention" if @unresolved_count.positive?
      return "Fast-pass complete" if parts.empty?

      "Fast-pass complete — #{parts.join(', ')}"
    end

    def empty_result(message)
      Result.new(
        resolved_count: 0,
        unresolved_count: 0,
        unmatched_rows: [],
        stage_message: message
      )
    end
  end
end
