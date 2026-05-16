# frozen_string_literal: true

# OAuth and webhooks may reach Rails via Next.js rewrites on the same public host.
# Prefer the canonical HOST env so redirect URIs match Shopify Partners settings.
Rails.application.config.to_prepare do
  next if ENV["HOST"].blank?

  canonical = ENV.fetch("HOST").to_s.strip.delete_suffix("/")
  canonical = "https://#{canonical}" unless canonical.start_with?("http")

  ShopifyAPI::Context.host = canonical if defined?(ShopifyAPI::Context)
rescue StandardError
  nil
end
