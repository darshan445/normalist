class Merchant < ApplicationRecord
  include MerchantShopifySession

  has_many :suppliers, dependent: :destroy
  has_many :variants, dependent: :destroy
  has_many :supplier_profiles, dependent: :destroy
  has_many :mapping_dictionaries, dependent: :destroy
  has_many :supplier_uploads, dependent: :destroy
  has_many :catalog_imports, dependent: :destroy

  validates :name, presence: true
  validates :platform_domain,
    uniqueness: { case_sensitive: false, allow_nil: true }
  validates :platform, inclusion: { in: %w[shopify], allow_nil: true }
end
