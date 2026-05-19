# frozen_string_literal: true

class AddPlatformInventoryIdToMappingDictionaries < ActiveRecord::Migration[8.1]
  def change
    add_column :mapping_dictionaries,
      :platform_inventory_id,
      :string
  end
end
