# frozen_string_literal: true

class MoveFileSchemaMapToSupplierProfiles < ActiveRecord::Migration[8.1]
  def up
    rename_column :supplier_profiles, :sku_column_name, :unique_column
    rename_column :supplier_profiles, :quantity_column_name, :quantity_column

    add_column :supplier_profiles, :barcode_column, :string
    add_column :supplier_profiles, :file_schema_map, :jsonb, default: {}, null: false

    migrate_supplier_schema_maps_to_profiles

    remove_column :suppliers, :file_schema_map
  end

  def down
    add_column :suppliers, :file_schema_map, :jsonb, default: {}, null: false

    execute <<~SQL.squish
      UPDATE suppliers s
      SET file_schema_map = sp.file_schema_map
      FROM supplier_profiles sp
      WHERE sp.supplier_id = s.id
    SQL

    remove_column :supplier_profiles, :file_schema_map
    remove_column :supplier_profiles, :barcode_column

    rename_column :supplier_profiles, :unique_column, :sku_column_name
    rename_column :supplier_profiles, :quantity_column, :quantity_column_name
  end

  private

  def migrate_supplier_schema_maps_to_profiles
    return unless column_exists?(:suppliers, :file_schema_map)

    execute <<~SQL.squish
      UPDATE supplier_profiles sp
      SET
        file_schema_map = s.file_schema_map,
        unique_column = COALESCE(
          NULLIF(sp.unique_column, ''),
          s.file_schema_map->>'supplier_unique_column'
        ),
        quantity_column = COALESCE(
          NULLIF(sp.quantity_column, ''),
          s.file_schema_map->>'supplier_quantity_column'
        ),
        barcode_column = COALESCE(
          sp.barcode_column,
          s.file_schema_map->>'supplier_barcode_column'
        ),
        raw_headers = CASE
          WHEN jsonb_array_length(COALESCE(sp.raw_headers, '[]'::jsonb)) > 0 THEN sp.raw_headers
          ELSE COALESCE(s.file_schema_map->'raw_headers', '[]'::jsonb)
        END
      FROM suppliers s
      WHERE sp.supplier_id = s.id
        AND s.file_schema_map IS NOT NULL
        AND s.file_schema_map != '{}'::jsonb
    SQL
  end
end
