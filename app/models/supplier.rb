class Supplier < ApplicationRecord
  include MerchantScoped

  has_one :supplier_profile, dependent: :destroy
  has_many :mapping_dictionaries, dependent: :destroy
  has_many :supplier_uploads, dependent: :destroy

  validates :name, presence: true
end
