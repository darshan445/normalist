# frozen_string_literal: true

class AddPendingColumnMappingToSupplierUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :supplier_uploads, :pending_column_mapping, :jsonb
  end
end
