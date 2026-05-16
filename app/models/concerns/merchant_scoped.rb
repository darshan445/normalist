module MerchantScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :merchant
    scope :for_merchant, ->(merchant) { where(merchant: merchant) }
  end
end
