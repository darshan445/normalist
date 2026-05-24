# frozen_string_literal: true

class Merchant < ApplicationRecord
  include MerchantShopifySession

  PLAN_STATUSES = %w[trialing active frozen cancelled].freeze

  has_many :suppliers, dependent: :destroy
  has_many :variants, dependent: :destroy
  has_many :supplier_profiles, dependent: :destroy
  has_many :mapping_dictionaries, dependent: :destroy
  has_many :supplier_uploads, dependent: :destroy
  has_many :subscriptions
  has_many :plan_changes

  has_one :active_subscription, -> {
    active.order(created_at: :desc)
  }, class_name: "Subscription"

  validates :name, presence: true
  validates :platform_domain,
    uniqueness: { case_sensitive: false, allow_nil: true }
  validates :platform, inclusion: { in: %w[shopify], allow_nil: true }
  validates :plan_status, inclusion: { in: PLAN_STATUSES }

  def current_plan
    sub = access_subscription
    return sub.plan if sub

    Plan.active.find_by(key: "starter") if trialing?
  end

  def has_access?
    return true if trialing?

    access_subscription.present?
  end

  def access_subscription
    expire_cancelled_subscriptions!
    active_subscription&.has_access? ? active_subscription : nil
  end

  def expire_cancelled_subscriptions!
    active_subscription&.expire_if_period_ended!
  end

  def trialing?
    plan_status == "trialing" &&
      trial_ends_at&.future?
  end

  def trial_expired?
    plan_status == "trialing" &&
      trial_ends_at&.past?
  end

  def trial_days_remaining
    return 0 unless trialing?

    ((trial_ends_at - Time.current) / 1.day).ceil
  end

  def trial_ending_soon?
    trialing? && trial_days_remaining <= 3
  end

  def subscribed?
    renewing?
  end

  def renewing?
    access_subscription.present? && !cancellation_pending?
  end

  def cancellation_pending?
    sub = active_subscription
    sub&.cancellation_pending? || false
  end

  def can_cancel_subscription?
    sub = active_subscription
    sub.present? && sub.cancelled_at.blank?
  end

  def access_ends_at
    access_subscription&.access_ends_at
  end

  def frozen?
    plan_status == "frozen"
  end

  def cancelled?
    plan_status == "cancelled" && !cancellation_pending?
  end

  def on_plan?(plan_key)
    current_plan&.key == plan_key
  end

  def feature_enabled?(feature_key)
    current_plan&.feature_enabled?(feature_key) || false
  end

  def feature_limit(feature_key)
    current_plan&.feature_limit(feature_key)
  end
end
