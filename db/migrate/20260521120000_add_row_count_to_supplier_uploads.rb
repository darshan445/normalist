# frozen_string_literal: true

class AddRowCountToSupplierUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :supplier_uploads, :row_count, :integer
  end
end
