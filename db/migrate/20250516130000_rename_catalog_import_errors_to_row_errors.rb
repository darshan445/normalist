class RenameCatalogImportErrorsToRowErrors < ActiveRecord::Migration[8.1]
  def change
    rename_column :catalog_imports, :errors, :row_errors
  end
end
