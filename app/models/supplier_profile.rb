class SupplierProfile < ApplicationRecord
  include MerchantScoped

  belongs_to :supplier

  validates :sku_column_name, :quantity_column_name, presence: true

  def profile_hash
    { sku_column: sku_column_name, quantity_column: quantity_column_name }
  end

  def touch_last_used!
    update!(last_used_at: Time.current)
  end
end
