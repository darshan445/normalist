# frozen_string_literal: true

class DropCatalogImports < ActiveRecord::Migration[8.1]
  def up
    ActiveStorage::Attachment.where(record_type: "CatalogImport").delete_all
    drop_table :catalog_imports, if_exists: true
  end

  def down
    create_table :catalog_imports, id: :uuid do |t|
      t.references :merchant, type: :uuid, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.integer :imported_count, default: 0, null: false
      t.integer :error_count, default: 0, null: false
      t.jsonb :row_errors, default: []
      t.text :error_message
      t.timestamps
    end
  end
end
