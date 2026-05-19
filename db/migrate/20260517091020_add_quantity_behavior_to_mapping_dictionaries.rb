# frozen_string_literal: true

class AddQuantityBehaviorToMappingDictionaries < ActiveRecord::Migration[8.1]
  def change
    add_column :mapping_dictionaries, :quantity_behavior,
      :string, null: false, default: "add"

    add_index :mapping_dictionaries, :quantity_behavior
  end
end
