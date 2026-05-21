require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.assume_ssl = true
  config.force_ssl = true
  config.log_tags = [ :request_id ]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false
  config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1") }
  config.active_job.queue_adapter = :sidekiq
  config.active_storage.service = :cloudflare_r2
  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]
  config.hosts << "api.normalist.space"
  config.hosts << "localhost"
  config.hosts << "127.0.0.1"
  config.host_authorization = {
    exclude: ->(request) { request.path == "/up" }
  }
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }
end

