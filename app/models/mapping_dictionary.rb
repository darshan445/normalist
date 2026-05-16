class MappingDictionary < ApplicationRecord
  include MerchantScoped

  belongs_to :supplier

  STATUSES = %w[active skipped pending].freeze

  validates :supplier_code, presence: true
  validates :supplier_code, uniqueness: { scope: [ :merchant_id, :supplier_id ] }
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :active, -> { where(status: "active") }
  scope :stale, -> { where("last_seen < ?", 180.days.ago) }

  def touch_last_seen!
    update!(last_seen: Time.current)
  end
end
