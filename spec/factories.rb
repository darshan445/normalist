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

    trait :review do
      status { "review" }
    end
  end

  factory :supplier_profile do
    merchant
    supplier
    unique_column { "ItemCode_Ref" }
    quantity_column { "Avail_Qty" }
    raw_headers { %w[ItemCode_Ref Avail_Qty Unit_Price] }
    file_schema_map { {} }
  end

  factory :feed do
    merchant
    supplier
    sequence(:name) { |n| "Feed #{n}" }
    feed_type { "file_upload" }
    status { "active" }
    config { {} }
  end

  factory :supplier_upload do
    merchant
    supplier
    status { "completed" }
    resolved_count { 10 }
    unresolved_count { 0 }

    to_create { |instance| instance.save(validate: false) }
  end
end
