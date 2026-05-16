Rails.application.routes.draw do
  require "sidekiq/web"

  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "session", to: "sessions#show"
      get "dashboard", to: "dashboard#show"
    end
  end

  # Shopify OAuth, webhooks (ShopifyApp::Engine)
  mount ShopifyApp::Engine, at: "/"

  get "/install", to: redirect { |_params, request|
    query = request.query_string.presence
    query ? "/login?#{query}" : "/login"
  }
end
