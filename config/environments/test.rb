require "active_support/core_ext/integer/time"

# Default env for test suite (ShopifyApp initializer requires these).
ENV["SHOPIFY_CLIENT_ID"] ||= "test_shopify_client_id"
ENV["SHOPIFY_CLIENT_SECRET"] ||= "test_shopify_client_secret"
ENV["HOST"] ||= "https://api.test.example"
ENV["FRONTEND_URL"] ||= "https://app.test.example"
ENV["CORS_ORIGINS"] ||= "https://app.test.example"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store
  config.action_dispatch.show_exceptions = :rescuable
  config.action_controller.allow_forgery_protection = false
  config.active_storage.service = :test
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
  config.active_job.queue_adapter = :test
  config.action_controller.raise_on_missing_callback_actions = true
  config.hosts.clear
end
