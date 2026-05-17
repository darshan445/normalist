# frozen_string_literal: true

class CreateFeeds < ActiveRecord::Migration[8.1]
  def change
    create_table :feeds, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :merchant_id, null: false
      t.uuid :supplier_id, null: false
      t.string :name, null: false
      t.string :feed_type, null: false
      t.jsonb :config, null: false, default: {}
      t.string :schedule
      t.string :status, null: false, default: "active"
      t.datetime :last_synced_at
      t.timestamps

      t.index [ :merchant_id, :supplier_id ]
      t.index [ :merchant_id, :status ]
      t.index :feed_type
    end

    add_foreign_key :feeds, :merchants
    add_foreign_key :feeds, :suppliers
  end
end
