# frozen_string_literal: true

class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans, id: :uuid,
                         default: -> { "gen_random_uuid()" } do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.decimal :price, null: false, precision: 10, scale: 2
      t.string :interval, null: false, default: "monthly"
      t.integer :trial_days, null: false, default: 14
      t.boolean :active, null: false, default: true
      t.boolean :public, null: false, default: true
      t.integer :sort_order, null: false, default: 0

      t.timestamps

      t.index :key, unique: true
      t.index :active
      t.index :public
      t.index :sort_order
    end
  end
end
