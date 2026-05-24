Plan.find_or_create_by!(key: "starter") do |plan|
  plan.name       = "NormaList"
  plan.price      = 14.00
  plan.interval   = "monthly"
  plan.trial_days = 14
  plan.active     = true
  plan.public     = true
  plan.sort_order = 1
end

starter = Plan.find_by!(key: "starter")

features = [
  { feature_key: "file_upload", enabled: true, limit_value: nil, limit_type: nil },
  { feature_key: "google_sheets", enabled: false, limit_value: nil, limit_type: nil },
  { feature_key: "ftp", enabled: false, limit_value: nil, limit_type: nil },
  { feature_key: "api_feed", enabled: false, limit_value: nil, limit_type: nil },
  { feature_key: "ai_detection", enabled: true, limit_value: nil, limit_type: nil },
  { feature_key: "stale_alerts", enabled: false, limit_value: nil, limit_type: nil },
  { feature_key: "analytics", enabled: false, limit_value: nil, limit_type: nil },
  { feature_key: "priority_support", enabled: false, limit_value: nil, limit_type: nil },
  { feature_key: "variant_limit", enabled: true, limit_value: nil, limit_type: "variants" },
  { feature_key: "supplier_limit", enabled: true, limit_value: nil, limit_type: "suppliers" },
  { feature_key: "upload_limit", enabled: true, limit_value: nil, limit_type: "uploads_per_month" }
]

features.each do |feature|
  PlanFeature.find_or_create_by!(
    plan: starter,
    feature_key: feature[:feature_key]
  ) do |pf|
    pf.enabled     = feature[:enabled]
    pf.limit_value = feature[:limit_value]
    pf.limit_type  = feature[:limit_type]
  end
end

merchant = Merchant.find_or_create_by!(name: "Demo Store")

supplier = merchant.suppliers.find_or_create_by!(name: "Acme Wholesale")

[
  [ "AERO-BLK-09", "Air Runner", "Black / Size 9", "1234567890123" ],
  [ "AERO-BLK-10", "Air Runner", "Black / Size 10", "1234567890124" ],
  [ "FOAM-GRY-09", "FoamStep", "Grey / Size 9", "1234567890125" ],
  [ "SOCK-WHT-OS", "Running Socks", "Default", nil ]
].each do |sku, product, variant, barcode|
  merchant.variants.find_or_create_by!(master_sku: sku) do |v|
    v.product_title = product
    v.variant_title = variant
    v.barcode = barcode
    v.status = "active"
  end
end

puts "Seeded plan: #{Plan.first&.key} — #{Plan.first&.name}"
puts "Seeded #{PlanFeature.count} plan features for starter"
puts "Seeded merchant: #{merchant.name} (#{merchant.id})"
puts "Seeded supplier: #{supplier.name}"
puts "Seeded #{merchant.variants.count} variants"
