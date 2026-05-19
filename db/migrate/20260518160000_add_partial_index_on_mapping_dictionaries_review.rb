# frozen_string_literal: true

class AddPartialIndexOnMappingDictionariesReview < ActiveRecord::Migration[8.1]
  def change
    add_index :mapping_dictionaries,
              %i[merchant_id supplier_id supplier_code],
              where: "status = 'review'",
              name: "index_mapping_dictionaries_on_merchant_supplier_review"
  end
end
