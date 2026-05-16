module Mapping
  class AutoMatcher
    def self.call(merchant:, supplier:, unresolved_rows:)
      new(merchant: merchant, supplier: supplier, unresolved_rows: unresolved_rows).call
    end

    def initialize(merchant:, supplier:, unresolved_rows:)
      @merchant = merchant
      @supplier = supplier
      @unresolved_rows = unresolved_rows
    end

    def call
      resolved = []
      still_unresolved = []

      @unresolved_rows.each do |row|
        variant = match_variant(row.supplier_code)
        if variant
          mapping = row.mapping_dictionary
          mapping.update!(
            status: "active",
            master_sku: variant.master_sku,
            last_seen: Time.current
          )
          resolved << DictionaryLookup::ResolvedRow.new(
            supplier_code: row.supplier_code,
            quantity: row.quantity,
            master_sku: variant.master_sku,
            variant: variant,
            mapping_dictionary: mapping
          )
        else
          still_unresolved << row
        end
      end

      { resolved: resolved, unresolved: still_unresolved }
    end

    private

    def match_variant(supplier_code)
      @merchant.variants.active.find_by(master_sku: supplier_code) ||
        @merchant.variants.active.find_by(barcode: supplier_code)
    end
  end
end
