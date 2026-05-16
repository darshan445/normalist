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

puts "Seeded merchant: #{merchant.name} (#{merchant.id})"
puts "Seeded supplier: #{supplier.name}"
puts "Seeded #{merchant.variants.count} variants"
