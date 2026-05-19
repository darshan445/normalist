Rails.application.routes.draw do
  require "sidekiq/web"

  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?

  get "up" => "rails/health#show", as: :rails_health_check

  post "/webhooks/products/create", to: "webhooks#product_create"
  post "/webhooks/products/update", to: "webhooks#product_update"
  post "/webhooks/products/delete", to: "webhooks#product_delete"
  post "/webhooks/inventory_items/create", to: "webhooks#inventory_item_create"
  post "/webhooks/inventory_items/update", to: "webhooks#inventory_item_update"
  post "/webhooks/inventory_levels/connect", to: "webhooks#inventory_level_connect"
  post "/webhooks/inventory_levels/update", to: "webhooks#inventory_level_update"

  namespace :api do
    namespace :v1 do
      get "session", to: "sessions#show"
      get "dashboard", to: "dashboard#show"
      get "catalog", to: "catalog#show"
      get "review_queue", to: "review_queue#index"
      post "review_queue/:mapping_id/confirm", to: "review_decisions#confirm"
      post "review_queue/:mapping_id/reject", to: "review_decisions#reject"
      post "review_queue/:mapping_id/manual_match", to: "review_decisions#manual_match"
      get "merchants/catalog_sync_status", to: "merchants#catalog_sync_status"
      resources :suppliers, only: %i[index show create] do
        resources :uploads, only: :show, module: :suppliers
        resources :feeds, only: %i[create show update], module: :suppliers do
          resource :upload, only: :create, controller: "feed_uploads"
        end
      end
    end
  end

  # Shopify OAuth, webhooks (ShopifyApp::Engine)
  mount ShopifyApp::Engine, at: "/"

  get "/install", to: redirect { |_params, request|
    query = request.query_string.presence
    query ? "/login?#{query}" : "/login"
  }
end
