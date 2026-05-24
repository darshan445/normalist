# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :merchant
  belongs_to :plan

  STATUSES = %w[
    pending
    accepted
    active
    declined
    expired
    cancelled
    frozen
  ].freeze

  INTERVALS = %w[monthly annual].freeze

  validates :shopify_charge_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :interval, inclusion: { in: INTERVALS }

  scope :active, -> { where(status: "active") }
  scope :trialing, -> { where(status: "accepted").where("trial_ends_at > ?", Time.current) }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :frozen, -> { where(status: "frozen") }
  scope :for_merchant, ->(id) { where(merchant_id: id) }

  def active?
    status == "active"
  end

  def trialing?
    status == "accepted" && trial_ends_at&.future?
  end

  def trial_expired?
    status == "accepted" && trial_ends_at&.past?
  end

  def cancelled?
    status == "cancelled"
  end

  def frozen?
    status == "frozen"
  end

  def has_access?
    active? || trialing?
  end

  def trial_days_remaining
    return 0 unless trialing?

    ((trial_ends_at - Time.current) / 1.day).ceil
  end
end
