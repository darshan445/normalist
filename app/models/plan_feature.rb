# frozen_string_literal: true

class PlanFeature < ApplicationRecord
  belongs_to :plan

  FEATURE_KEYS = %w[
    file_upload
    google_sheets
    ftp
    api_feed
    ai_detection
    stale_alerts
    analytics
    priority_support
    variant_limit
    supplier_limit
    upload_limit
  ].freeze

  LIMIT_TYPES = %w[
    variants
    suppliers
    uploads_per_month
  ].freeze

  validates :feature_key, presence: true,
                          inclusion: { in: FEATURE_KEYS },
                          uniqueness: { scope: :plan_id }
  validates :enabled, inclusion: { in: [ true, false ] }
  validates :limit_type, inclusion: { in: LIMIT_TYPES, allow_nil: true }
  validates :limit_value, numericality: { greater_than: 0, allow_nil: true }

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
  scope :for_feature, ->(key) { find_by(feature_key: key) }

  def unlimited?
    limit_value.nil?
  end

  def limit_feature?
    limit_type.present?
  end
end
