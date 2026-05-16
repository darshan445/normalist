module Compilation
  class Validator
    ValidatedRow = Data.define(:supplier_code, :quantity, :master_sku, :variant, :status)

    def self.call(merchant:, resolved_rows:)
      new(merchant: merchant, resolved_rows: resolved_rows).call
    end

    def initialize(merchant:, supplier: nil, resolved_rows:)
      @merchant = merchant
      @resolved_rows = resolved_rows
    end

    def call
      @resolved_rows.map do |row|
        variant = row.variant || @merchant.variants.find_by(master_sku: row.master_sku)

        if variant.nil? || variant.status == "deleted"
          ValidatedRow.new(
            supplier_code: row.supplier_code,
            quantity: row.quantity,
            master_sku: row.master_sku,
            variant: variant,
            status: "variant_deleted"
          )
        else
          ValidatedRow.new(
            supplier_code: row.supplier_code,
            quantity: row.quantity,
            master_sku: row.master_sku,
            variant: variant,
            status: "Ready_To_Sync"
          )
        end
      end
    end
  end
end
