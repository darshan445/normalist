# frozen_string_literal: true

class AddUniqueCodeCountToSupplierUploads < ActiveRecord::Migration[8.0]
  def change
    add_column :supplier_uploads, :unique_code_count, :integer
  end
end
