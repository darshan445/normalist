class Variant < ApplicationRecord
  include MerchantScoped
  include Neighbor::Model

  has_neighbors :embedding

  STATUSES = %w[active deleted].freeze

  validates :product_title, :variant_title, :master_sku, presence: true
  validates :master_sku, uniqueness: { scope: :merchant_id }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :needs_sku, -> { where(needs_sku: true) }
  scope :has_sku, -> { where(needs_sku: false) }
  
  def embedding_text
    [product_title, variant_title, master_sku, barcode].filter_map { |value| value.presence }.join(" | ")
  end

  scope :search, ->(query) {
    return all if query.blank?

    term = "%#{sanitize_sql_like(query.strip)}%"
    where(
      "product_title ILIKE :q OR variant_title ILIKE :q OR master_sku ILIKE :q OR barcode ILIKE :q",
      q: term
    )
  }
end
