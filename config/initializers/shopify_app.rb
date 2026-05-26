# frozen_string_literal: true

def frontend_app_url
  raw = ENV.fetch("FRONTEND_URL").to_s.strip.delete_suffix("/")
  raw.start_with?("http") ? raw : "https://#{raw}"
end

def shopify_app_host
  raw = ENV.fetch("HOST").to_s.strip.delete_suffix("/")
  raw.start_with?("http") ? raw : "https://#{raw}"
end

ShopifyApp.configure do |config|
  config.application_name = "NormaList"
  config.old_secret = ""
  config.scope = [
    "read_products",
    "write_products",
    "read_inventory",
    "write_inventory",
    "read_locations",
    "write_locations"
  ].join(", ")
  config.embedded_app = true
  config.new_embedded_auth_strategy = true
  config.disable_webpacker = true

  config.root_url = frontend_app_url

  config.after_authenticate_job = { job: "Shopify::AfterAuthenticateJob", inline: false }
  config.api_version = "2025-10"
  config.shop_session_repository = "Merchant"
  config.log_level = :info
  config.reauth_on_access_scope_changes = true
  config.check_session_expiry_date = true
  # GDPR/privacy topics are app-level only — see shopify.app.toml [webhooks.privacy_compliance].
  config.webhooks = [
    { topic: "app/uninstalled", address: "webhooks/app_uninstalled" },
    { topic: "products/create", address: "webhooks/products/create" },
    { topic: "products/update", address: "webhooks/products/update" },
    { topic: "products/delete", address: "webhooks/products/delete" },
    { topic: "inventory_items/create", address: "webhooks/inventory_items/create" },
    { topic: "inventory_items/update", address: "webhooks/inventory_items/update" },
    { topic: "inventory_levels/connect", address: "webhooks/inventory_levels/connect" },
    { topic: "inventory_levels/update", address: "webhooks/inventory_levels/update" },
    { topic: "app/subscriptions/update", address: "webhooks/app/subscriptions/update" }
  ]
  config.api_key = ENV.fetch("SHOPIFY_CLIENT_ID")
  config.secret = ENV.fetch("SHOPIFY_CLIENT_SECRET")
end

Rails.application.config.after_initialize do
  ShopifyAPI::Context.setup(
    api_key: ShopifyApp.configuration.api_key,
    api_secret_key: ShopifyApp.configuration.secret,
    api_version: ShopifyApp.configuration.api_version,
    host: shopify_app_host,
    scope: ShopifyApp.configuration.scope,
    is_private: !ENV.fetch("SHOPIFY_APP_PRIVATE_SHOP", "").empty?,
    is_embedded: ShopifyApp.configuration.embedded_app,
    expiring_offline_access_tokens: true,
    log_level: :info,
    logger: Rails.logger,
    private_shop: ENV.fetch("SHOPIFY_APP_PRIVATE_SHOP", nil),
    user_agent_prefix: "ShopifyApp/#{ShopifyApp::VERSION}"
  )

end

Rails.application.config.to_prepare do
  register_shopify_webhook_handlers!
end

def register_shopify_webhook_handlers!
  register_shopify_standard_webhook_handlers!
  register_shopify_privacy_webhook_handlers!
end

def register_shopify_standard_webhook_handlers!
  standard_handlers = {
    "app/uninstalled" => [ "webhooks/app_uninstalled", Shopify::AppUninstalledHandler.new ],
    "products/create" => [ "webhooks/products/create", WebhooksController::ProductsCreateHandler.new ],
    "products/update" => [ "webhooks/products/update", WebhooksController::ProductsUpdateHandler.new ],
    "products/delete" => [ "webhooks/products/delete", WebhooksController::ProductsDeleteHandler.new ],
    "inventory_items/create" => [
      "webhooks/inventory_items/create",
      WebhooksController::InventoryItemsCreateHandler.new
    ],
    "inventory_items/update" => [
      "webhooks/inventory_items/update",
      WebhooksController::InventoryItemsUpdateHandler.new
    ],
    "inventory_levels/connect" => [
      "webhooks/inventory_levels/connect",
      WebhooksController::InventoryLevelsConnectHandler.new
    ],
    "inventory_levels/update" => [
      "webhooks/inventory_levels/update",
      WebhooksController::InventoryLevelsUpdateHandler.new
    ],
    "app/subscriptions/update" => [
      "webhooks/app/subscriptions/update",
      Billing::AppSubscriptionsUpdateHandler.new
    ]
  }

  standard_handlers.each do |topic, (path, handler)|
    ShopifyAPI::Webhooks::Registry.add_registration(
      topic: topic,
      delivery_method: :http,
      path: path,
      handler: handler
    )
  end
end

def register_shopify_privacy_webhook_handlers!
  Shopify::PrivacyWebhookHandlers.register!
end
