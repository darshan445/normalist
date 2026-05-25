require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module Normalist
  class Application < Rails::Application
    config.load_defaults 8.1

    config.api_only = true

    config.paths.add "public", with: "public"

    config.public_file_server.enabled = true

    config.autoload_lib(ignore: %w[assets tasks])
    config.autoload_paths << Rails.root.join("app/services")
    config.eager_load_paths << Rails.root.join("app/services")
    config.autoload_paths << Rails.root.join("app/handlers")
    config.eager_load_paths << Rails.root.join("app/handlers")
    # config.hosts << "reemerge-obstinate-latter.ngrok-free.dev"



    config.active_job.queue_adapter = :sidekiq
    config.active_job.enqueue_after_transaction_commit = :always

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
  end
end
