# frozen_string_literal: true

class CreatePlanFeatures < ActiveRecord::Migration[8.1]
  def change
    create_table :plan_features, id: :uuid,
                                  default: -> { "gen_random_uuid()" } do |t|
      t.references :plan, type: :uuid, null: false, foreign_key: true
      t.string :feature_key, null: false
      t.boolean :enabled, null: false, default: true
      t.integer :limit_value
      t.string :limit_type

      t.timestamps

      t.index %i[plan_id feature_key], unique: true
      t.index :feature_key
      t.index :enabled
    end
  end
end
