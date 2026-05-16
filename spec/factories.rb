FactoryBot.define do
  factory :merchant do
    sequence(:name) { |n| "Merchant #{n}" }
  end

  factory :supplier do
    merchant
    sequence(:name) { |n| "Supplier #{n}" }
  end

  factory :variant do
    merchant
    sequence(:product_title) { |n| "Product #{n}" }
    sequence(:variant_title) { |n| "Variant #{n}" }
    sequence(:master_sku) { |n| "SKU-#{n}" }
    status { "active" }
  end

  factory :mapping_dictionary do
    merchant
    supplier
    sequence(:supplier_code) { |n| "SUP-#{n}" }
    status { "pending" }
  end

  factory :supplier_profile do
    merchant
    supplier
    sku_column_name { "ItemCode_Ref" }
    quantity_column_name { "Avail_Qty" }
    raw_headers { %w[ItemCode_Ref Avail_Qty Unit_Price] }
  end
end
