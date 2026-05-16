class CreateNormaListSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :merchants, id: :uuid do |t|
      t.string :name, null: false
      t.string :platform
      t.string :platform_domain
      t.string :access_token
      t.datetime :catalog_synced_at
      t.timestamps
    end

    create_table :suppliers, id: :uuid do |t|
      t.references :merchant, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end

    create_table :variants, id: :uuid do |t|
      t.references :merchant, type: :uuid, null: false, foreign_key: true
      t.string :product_title, null: false
      t.string :variant_title, null: false
      t.string :master_sku, null: false
      t.string :barcode
      t.string :platform
      t.string :platform_variant_id
      t.string :platform_inventory_id
      t.string :status, null: false, default: "active"
      t.datetime :synced_at
      t.timestamps

      t.index [ :merchant_id, :master_sku ], unique: true
      t.index [ :merchant_id, :barcode ]
      t.index [ :merchant_id, :platform_variant_id ]
      t.index [ :merchant_id, :status ]
    end

    create_table :supplier_profiles, id: :uuid do |t|
      t.references :merchant, type: :uuid, null: false, foreign_key: true
      t.references :supplier, type: :uuid, null: false, foreign_key: true
      t.string :sku_column_name, null: false
      t.string :quantity_column_name, null: false
      t.jsonb :raw_headers, null: false, default: []
      t.datetime :last_used_at
      t.timestamps

      t.index [ :merchant_id, :supplier_id ], unique: true
    end

    create_table :mapping_dictionaries, id: :uuid do |t|
      t.references :merchant, type: :uuid, null: false, foreign_key: true
      t.references :supplier, type: :uuid, null: false, foreign_key: true
      t.string :supplier_code, null: false
      t.string :master_sku
      t.string :platform_variant_id
      t.string :status, null: false, default: "pending"
      t.datetime :last_seen
      t.timestamps

      t.index [ :merchant_id, :supplier_id, :supplier_code ], unique: true, name: "index_mapping_dict_on_merchant_supplier_code"
      t.index [ :merchant_id, :status ]
      t.index :last_seen
    end

    create_table :supplier_uploads, id: :uuid do |t|
      t.references :merchant, type: :uuid, null: false, foreign_key: true
      t.references :supplier, type: :uuid, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :stage
      t.jsonb :output, default: []
      t.integer :resolved_count, default: 0, null: false
      t.integer :unresolved_count, default: 0, null: false
      t.text :error_message
      t.timestamps

      t.index [ :merchant_id, :status ]
    end

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
