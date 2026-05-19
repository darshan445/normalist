# frozen_string_literal: true

class AddFileSchemaMapToSuppliers < ActiveRecord::Migration[8.1]
  def change
    add_column :suppliers, :file_schema_map, :jsonb, default: {}, null: false
  end
end
