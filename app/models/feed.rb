# frozen_string_literal: true

class Feed < ApplicationRecord
  belongs_to :merchant
  belongs_to :supplier
  has_many :supplier_uploads, dependent: :nullify

  FEED_TYPES = %w[file_upload google_sheets ftp api].freeze
  CREATABLE_FEED_TYPES = %w[file_upload google_sheets].freeze
  STATUSES = %w[active paused error].freeze
  SYNC_INTERVALS = %w[every_6_hours every_12_hours daily weekly].freeze
  DEFAULT_SYNC_INTERVAL = "daily"
  SYNC_INTERVAL_DURATIONS = {
    "every_6_hours" => 6.hours,
    "every_12_hours" => 12.hours,
    "daily" => 1.day,
    "weekly" => 1.week
  }.freeze

  validates :name, presence: true
  validates :feed_type, inclusion: { in: FEED_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validate :creatable_feed_type, on: :create
  validate :unique_feed_type_per_supplier, on: :create
  validate :google_sheets_config_present, if: :google_sheets?

  def self.creatable_feed_types
    CREATABLE_FEED_TYPES
  end

  scope :active, -> { where(status: "active") }
  scope :file_uploads, -> { where(feed_type: "file_upload") }
  scope :google_sheets, -> { where(feed_type: "google_sheets") }
  scope :for_merchant, ->(merchant_id) { where(merchant_id: merchant_id) }

  def file_upload?
    feed_type == "file_upload"
  end

  def google_sheets?
    feed_type == "google_sheets"
  end

  def sync_interval
    interval = config["interval"].presence || DEFAULT_SYNC_INTERVAL
    SYNC_INTERVALS.include?(interval) ? interval : DEFAULT_SYNC_INTERVAL
  end

  def sync_interval_duration
    SYNC_INTERVAL_DURATIONS.fetch(sync_interval, SYNC_INTERVAL_DURATIONS[DEFAULT_SYNC_INTERVAL])
  end

  def sync_due?(at: Time.current)
    return false unless google_sheets? && status == "active"

    last_synced_at.nil? || last_synced_at <= (at - sync_interval_duration)
  end

  def sync_in_progress?
    supplier_uploads.where(status: %w[pending processing]).exists?
  end

  def manual?
    schedule.blank?
  end

  def scheduled?
    schedule.present?
  end

  private

  def creatable_feed_type
    return if CREATABLE_FEED_TYPES.include?(feed_type)

    errors.add(:feed_type, "is not supported")
  end

  def google_sheets_config_present
    errors.add(:url, "is required for Google Sheets feeds") if config["url"].blank?
    errors.add(:tab_gid, "is required for Google Sheets feeds") if config["tab_gid"].blank?
  end

  def unique_feed_type_per_supplier
    return if supplier_id.blank? || feed_type.blank?
    return unless CREATABLE_FEED_TYPES.include?(feed_type)

    existing = Feed.where(supplier_id:, feed_type:).where.not(id: id)
    return unless existing.exists?

    errors.add(:feed_type, "already exists for this supplier")
  end
end
