# frozen_string_literal: true

class AddTrialAndPlanStatusToMerchants < ActiveRecord::Migration[8.1]
  def change
    add_column :merchants, :plan_status, :string, null: false, default: "trialing"
    add_column :merchants, :trial_starts_at, :datetime
    add_column :merchants, :trial_ends_at, :datetime

    add_index :merchants, :trial_ends_at

    if column_exists?(:merchants, :pending_charge_url)
      remove_column :merchants, :pending_charge_url, :string
    end
  end
end
