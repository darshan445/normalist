# frozen_string_literal: true

class Feed < ApplicationRecord
  belongs_to :merchant
  belongs_to :supplier
  has_many :supplier_uploads, dependent: :nullify

  FEED_TYPES = %w[file_upload google_sheets ftp api].freeze
  STATUSES = %w[active paused error].freeze

  validates :name, presence: true
  validates :feed_type, inclusion: { in: FEED_TYPES }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :file_uploads, -> { where(feed_type: "file_upload") }
  scope :for_merchant, ->(merchant_id) { where(merchant_id: merchant_id) }

  def file_upload?
    feed_type == "file_upload"
  end

  def google_sheets?
    feed_type == "google_sheets"
  end

  def manual?
    schedule.blank?
  end

  def scheduled?
    schedule.present?
  end
end
