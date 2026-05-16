# frozen_string_literal: true

# shopify_app engine registers asset precompile paths; API-only apps have no asset pipeline.
Rails.application.config.assets = ActiveSupport::OrderedOptions.new
Rails.application.config.assets.precompile = []
