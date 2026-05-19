# frozen_string_literal: true

class RemovePendingColumnMappingFromSupplierUploads < ActiveRecord::Migration[8.1]
  def change
    remove_column :supplier_uploads, :pending_column_mapping, :jsonb
  end
end
