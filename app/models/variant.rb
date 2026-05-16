class Variant < ApplicationRecord
  include MerchantScoped

  STATUSES = %w[active deleted].freeze

  validates :product_title, :variant_title, :master_sku, presence: true
  validates :master_sku, uniqueness: { scope: :merchant_id }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :search, ->(query) {
    return all if query.blank?

    term = "%#{sanitize_sql_like(query.strip)}%"
    where(
      "product_title ILIKE :q OR variant_title ILIKE :q OR master_sku ILIKE :q OR barcode ILIKE :q",
      q: term
    )
  }
end
