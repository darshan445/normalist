class SupplierProfile < ApplicationRecord
  include MerchantScoped

  belongs_to :supplier

  validates :unique_column, :quantity_column, presence: true

  def profile_hash
    {
      unique_column: unique_column,
      sku_column: unique_column,
      quantity_column: quantity_column,
      barcode_column: barcode_column
    }
  end

  def touch_last_used!
    update!(last_used_at: Time.current)
  end

  def refresh_from_upload!(headers:)
    update!(
      raw_headers: headers,
      last_used_at: Time.current
    )
  end

  def ready?
    unique_column.present? && quantity_column.present?
  end

  def apply_schema_discovery!(headers:, mapping:)
    schema_map = mapping.merge(
      "raw_headers" => headers,
      "discovered_at" => Time.current.iso8601
    )

    assign_attributes(
      unique_column: mapping["supplier_unique_column"],
      quantity_column: mapping["supplier_quantity_column"],
      barcode_column: mapping["supplier_barcode_column"],
      raw_headers: headers,
      file_schema_map: schema_map,
      last_used_at: Time.current
    )
    save!

    schema_map
  end
end
