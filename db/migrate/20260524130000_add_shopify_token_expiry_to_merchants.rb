# frozen_string_literal: true

class AddShopifyTokenExpiryToMerchants < ActiveRecord::Migration[8.1]
  def change
    add_column :merchants, :expires_at, :datetime
    add_column :merchants, :refresh_token, :string
    add_column :merchants, :refresh_token_expires_at, :datetime
  end
end
