module Compilation
  class Engine
    def self.call(validated_rows:, needs_review_rows: [])
      new(validated_rows: validated_rows, needs_review_rows: needs_review_rows).call
    end

    def initialize(validated_rows:, needs_review_rows: [])
      @validated_rows = validated_rows
      @needs_review_rows = needs_review_rows
    end

    def call
      ready = @validated_rows.map { |row| build_entry(row) }
      review = @needs_review_rows.map { |row| build_needs_review(row) }
      ready + review
    end

    private

    def build_entry(row)
      {
        supplier_code: row.supplier_code,
        master_sku: row.master_sku,
        platform_variant_id: row.variant&.platform_variant_id,
        platform_inventory_id: row.variant&.platform_inventory_id,
        quantity: row.quantity,
        status: row.status
      }
    end

    def build_needs_review(row)
      {
        supplier_code: row.supplier_code,
        master_sku: nil,
        platform_variant_id: nil,
        platform_inventory_id: nil,
        quantity: row.quantity,
        status: "Needs_Review"
      }
    end
  end
end
