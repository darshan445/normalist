module Mapping
  class DictionaryLookup
    ResolvedRow = Data.define(:supplier_code, :quantity, :master_sku, :variant, :mapping_dictionary)
    UnresolvedRow = Data.define(:supplier_code, :quantity, :raw_row, :mapping_dictionary)

    def self.call(merchant:, supplier:, extracted_rows:)
      new(merchant: merchant, supplier: supplier, extracted_rows: extracted_rows).call
    end

    def initialize(merchant:, supplier:, extracted_rows:)
      @merchant = merchant
      @supplier = supplier
      @extracted_rows = extracted_rows
    end

    def call
      resolved = []
      unresolved = []

      @extracted_rows.each do |row|
        mapping = find_or_build_mapping(row[:supplier_code])
        mapping.touch_last_seen!

        if mapping.status == "mapped" && mapping.master_sku.present?
          variant = @merchant.variants.active.find_by(master_sku: mapping.master_sku)
          resolved << ResolvedRow.new(
            supplier_code: row[:supplier_code],
            quantity: row[:quantity],
            master_sku: mapping.master_sku,
            variant: variant,
            mapping_dictionary: mapping
          )
        elsif mapping.status == "skipped"
          next
        elsif mapping.status.in?(%w[pending review])
          unresolved << UnresolvedRow.new(
            supplier_code: row[:supplier_code],
            quantity: row[:quantity],
            raw_row: row[:raw_row],
            mapping_dictionary: mapping
          )
        end
      end

      { resolved: resolved, unresolved: unresolved }
    end

    private

    def find_or_build_mapping(supplier_code)
      @merchant.mapping_dictionaries.find_or_initialize_by(
        supplier: @supplier,
        supplier_code: supplier_code
      ).tap do |m|
        m.status = "pending" if m.new_record?
        m.save! if m.changed? || m.new_record?
      end
    end
  end
end
