class MigrateShopifySessionsToMerchants < ActiveRecord::Migration[8.1]
  class Shop < ActiveRecord::Base
    self.table_name = "shops"
  end

  def up
    migrate_shop_records_to_merchants if table_exists?(:shops)
    drop_table :shops, if_exists: true

    return if index_exists?(:merchants, :platform_domain, name: "index_merchants_on_platform_domain")

    add_index :merchants,
      :platform_domain,
      unique: true,
      where: "platform_domain IS NOT NULL",
      name: "index_merchants_on_platform_domain"
  end

  def down
    remove_index :merchants, name: "index_merchants_on_platform_domain", if_exists: true

    create_table :shops do |t|
      t.string :shopify_domain, null: false
      t.string :shopify_token, null: false
      t.timestamps
    end

    add_index :shops, :shopify_domain, unique: true
  end

  private

  def migrate_shop_records_to_merchants
    Shop.find_each do |shop|
      merchant = Merchant.find_or_initialize_by(platform_domain: shop.shopify_domain)
      merchant.access_token = shop.shopify_token
      merchant.platform = "shopify"
      merchant.name = merchant.name.presence || shop.shopify_domain.sub(/\.myshopify\.com\z/i, "").tr("-", " ").titleize
      merchant.save!
    end
  end
end
