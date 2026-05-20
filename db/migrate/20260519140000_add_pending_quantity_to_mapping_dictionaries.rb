# frozen_string_literal: true

class AddPendingQuantityToMappingDictionaries < ActiveRecord::Migration[8.0]
  def change
    return if column_exists?(:mapping_dictionaries, :pending_quantity)

    add_column :mapping_dictionaries, :pending_quantity, :integer
  end
end
