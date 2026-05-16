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
  config.scope = "read_products, write_inventory, read_inventory"
  config.embedded_app = true
  config.new_embedded_auth_strategy = true
  config.disable_webpacker = true

  config.root_url = frontend_app_url

  config.after_authenticate_job = { job: "Shopify::AfterAuthenticateJob", inline: false }
  config.api_version = "2025-10"
  config.shop_session_repository = "Merchant"
  config.log_level = :info
  config.reauth_on_access_scope_changes = true
  config.webhooks = [
    { topic: "app/uninstalled", address: "webhooks/app_uninstalled" },
    { topic: "customers/data_request", address: "webhooks/customers_data_request" },
    { topic: "customers/redact", address: "webhooks/customers_redact" },
    { topic: "shop/redact", address: "webhooks/shop_redact" }
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
    log_level: :info,
    logger: Rails.logger,
    private_shop: ENV.fetch("SHOPIFY_APP_PRIVATE_SHOP", nil),
    user_agent_prefix: "ShopifyApp/#{ShopifyApp::VERSION}"
  )

  register_shopify_webhook_handlers!
end

def register_shopify_webhook_handlers!
  handlers = {
    "app/uninstalled" => [ "webhooks/app_uninstalled", Shopify::AppUninstalledHandler.new ],
    "customers/data_request" => [ "webhooks/customers_data_request", Shopify::CustomersDataRequestHandler.new ],
    "customers/redact" => [ "webhooks/customers_redact", Shopify::CustomersRedactHandler.new ],
    "shop/redact" => [ "webhooks/shop_redact", Shopify::ShopRedactHandler.new ]
  }

  handlers.each do |topic, (path, handler)|
    ShopifyAPI::Webhooks::Registry.add_registration(
      topic: topic,
      delivery_method: :http,
      path: path,
      handler: handler
    )
  end
end
