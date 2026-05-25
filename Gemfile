source "https://rubygems.org"

gem "rails", "~> 8.1.0"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# API
gem "rack-cors"

# Background processing
gem "sidekiq"
gem "sidekiq-cron"
gem "redis"

# File parsing & AI
gem "roo"
gem "faraday"
gem "neighbor"
gem "pgvector"

# Shopify OAuth and webhooks
gem "shopify_app"

gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

# Active Storage for supplier/catalog file uploads (Cloudflare R2 uses S3 API)
gem "aws-sdk-s3", require: false
gem "image_processing", "~> 1.2"

# Admin panel (RailsAdmin) + asset pipeline
gem "rails_admin", "~> 3.3"
gem "sprockets-rails", "~> 3.5"
gem "sassc-rails", "~> 2.1"

group :development, :test do
  gem "dotenv-rails"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end
