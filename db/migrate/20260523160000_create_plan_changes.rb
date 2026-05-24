# frozen_string_literal: true

class CreatePlanChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :plan_changes, id: :uuid,
                                default: -> { "gen_random_uuid()" } do |t|
      t.references :merchant, type: :uuid, null: false, foreign_key: true
      t.references :subscription, type: :uuid, null: true, foreign_key: true

      t.string :from_plan
      t.string :to_plan, null: false
      t.string :reason, null: false
      t.string :initiated_by, null: false, default: "merchant"
      t.text :note

      t.timestamps

      t.index %i[merchant_id created_at]
      t.index :reason
      t.index :initiated_by
      t.index :to_plan
    end
  end
end
