# frozen_string_literal: true

class PlanChange < ApplicationRecord
  belongs_to :merchant
  belongs_to :subscription, optional: true

  REASONS = %w[
    install
    upgrade
    downgrade
    cancel
    trial_expired
    payment_failed
    payment_resumed
    reinstall
    admin
  ].freeze

  INITIATED_BY = %w[
    merchant
    system
    admin
  ].freeze

  validates :to_plan, presence: true
  validates :reason, presence: true, inclusion: { in: REASONS }
  validates :initiated_by, inclusion: { in: INITIATED_BY }

  scope :for_merchant, ->(id) { where(merchant_id: id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :upgrades, -> { where(reason: "upgrade") }
  scope :downgrades, -> { where(reason: "downgrade") }
  scope :cancellations, -> { where(reason: "cancel") }
  scope :by_system, -> { where(initiated_by: "system") }
  scope :by_merchant, -> { where(initiated_by: "merchant") }

  def upgrade?
    reason == "upgrade"
  end

  def downgrade?
    reason == "downgrade"
  end

  def cancellation?
    reason == "cancel"
  end

  def first_install?
    reason == "install" && from_plan.nil?
  end
end
