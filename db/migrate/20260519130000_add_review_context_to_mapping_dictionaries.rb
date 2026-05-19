# frozen_string_literal: true

class AddReviewContextToMappingDictionaries < ActiveRecord::Migration[8.1]
  def change
    add_reference :mapping_dictionaries, :supplier_upload, type: :uuid, foreign_key: true, null: true, index: true
    add_column :mapping_dictionaries, :confidence_score, :float
  end
end
