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
  scope :cancellation_pending, -> {
    active.where.not(cancelled_at: nil)
  }

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

  def cancellation_pending?
    active? && cancelled_at.present? && within_paid_period?
  end

  def access_ends_at
    billing_on
  end

  def within_paid_period?
    return true if cancelled_at.blank?

    billing_on.present? && billing_on.end_of_day >= Time.current
  end

  def expire_if_period_ended!
    return unless active?
    return if cancelled_at.blank?
    return if within_paid_period?

    update!(status: "cancelled")
  end

  def has_access?
    active? && within_paid_period?
  end

  def trial_days_remaining
    return 0 unless trialing?

    ((trial_ends_at - Time.current) / 1.day).ceil
  end
end
