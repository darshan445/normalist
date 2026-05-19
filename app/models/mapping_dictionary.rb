class MappingDictionary < ApplicationRecord
  include MerchantScoped

  belongs_to :supplier
  belongs_to :supplier_upload, optional: true

  STATUSES = %w[mapped pending review skipped].freeze
  QUANTITY_BEHAVIORS = %w[add replace].freeze

  validates :supplier_code, presence: true
  validates :supplier_code, uniqueness: { scope: [ :merchant_id, :supplier_id ] }
  validates :status, inclusion: { in: STATUSES }
  validates :quantity_behavior, inclusion: { in: QUANTITY_BEHAVIORS }

  scope :mapped, -> { where(status: "mapped") }
  scope :pending, -> { where(status: "pending") }
  scope :review, -> { where(status: "review") }
  scope :skipped, -> { where(status: "skipped") }
  scope :needs_attention, -> { where(status: %w[pending review]) }
  scope :stale, -> { where("last_seen < ?", 180.days.ago) }

  def touch_last_seen!
    update!(last_seen: Time.current)
  end
end
