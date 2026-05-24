# frozen_string_literal: true

class Plan < ApplicationRecord
  has_many :plan_features, dependent: :destroy
  has_many :subscriptions

  INTERVALS = %w[monthly annual].freeze

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
  validates :price, presence: true,
                    numericality: { greater_than_or_equal_to: 0 }
  validates :interval, inclusion: { in: INTERVALS }
  validates :trial_days, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :visible, -> { where(public: true) }
  scope :ordered, -> { order(:sort_order) }

  def free?
    price.zero?
  end

  def monthly?
    interval == "monthly"
  end

  def annual?
    interval == "annual"
  end

  def feature_enabled?(feature_key)
    plan_features
      .find_by(feature_key: feature_key)
      &.enabled? || false
  end

  def feature_limit(feature_key)
    plan_features
      .find_by(feature_key: feature_key)
      &.limit_value
  end
end
