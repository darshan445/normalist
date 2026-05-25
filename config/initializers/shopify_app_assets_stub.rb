# frozen_string_literal: true

# shopify_app references the asset pipeline for OAuth views. Extend precompile paths
# without replacing the Sprockets configuration used by RailsAdmin.
Rails.application.config.assets.precompile ||= []
