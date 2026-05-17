# frozen_string_literal: true

class AddFeedIdToSupplierUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :supplier_uploads, :feed_id, :uuid
    add_index :supplier_uploads, :feed_id
    add_foreign_key :supplier_uploads, :feeds
  end
end
