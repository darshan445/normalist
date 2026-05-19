# frozen_string_literal: true

class AddLocationIdToMerchants < ActiveRecord::Migration[8.1]
  def change
    add_column :merchants, :location_id, :string
  end
end
