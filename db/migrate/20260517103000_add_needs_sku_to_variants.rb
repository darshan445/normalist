# frozen_string_literal: true

class AddNeedsSkuToVariants < ActiveRecord::Migration[8.1]
  def change
    add_column :variants, :needs_sku, :boolean, null: false, default: false
    add_index :variants, %i[merchant_id needs_sku]
  end
end
