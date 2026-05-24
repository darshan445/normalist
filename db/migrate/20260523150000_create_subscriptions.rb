# frozen_string_literal: true

class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions, id: :uuid,
                                   default: -> { "gen_random_uuid()" } do |t|
      t.references :merchant, type: :uuid, null: false, foreign_key: true
      t.references :plan, type: :uuid, null: false, foreign_key: true

      t.string :shopify_charge_id, null: false
      t.string :status, null: false, default: "pending"
      t.decimal :price, null: false, precision: 10, scale: 2
      t.string :interval, null: false, default: "monthly"
      t.integer :trial_days, default: 14

      t.datetime :trial_ends_at
      t.datetime :activated_at
      t.datetime :billing_on
      t.datetime :cancelled_at
      t.datetime :frozen_at

      t.jsonb :shopify_payload, null: false, default: {}

      t.timestamps

      t.index :shopify_charge_id, unique: true
      t.index %i[merchant_id status]
      t.index :status
      t.index :billing_on
      t.index :activated_at
    end
  end
end
