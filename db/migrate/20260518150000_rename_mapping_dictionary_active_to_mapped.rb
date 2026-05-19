# frozen_string_literal: true

class RenameMappingDictionaryActiveToMapped < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE mapping_dictionaries
      SET status = 'mapped'
      WHERE status = 'active'
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE mapping_dictionaries
      SET status = 'active'
      WHERE status = 'mapped'
    SQL
  end
end
