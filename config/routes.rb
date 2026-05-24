Rails.application.routes.draw do
  require "sidekiq/web"

  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?

  get "up" => "rails/health#show", as: :rails_health_check

  get "/billing", to: "billing#show", as: :billing
  get "/billing/callback", to: "billing#callback", as: :billing_callback

  post "/webhooks/products/create", to: "webhooks#product_create"
  post "/webhooks/products/update", to: "webhooks#product_update"
  post "/webhooks/products/delete", to: "webhooks#product_delete"
  post "/webhooks/inventory_items/create", to: "webhooks#inventory_item_create"
  post "/webhooks/inventory_items/update", to: "webhooks#inventory_item_update"
  post "/webhooks/inventory_levels/connect", to: "webhooks#inventory_level_connect"
  post "/webhooks/inventory_levels/update", to: "webhooks#inventory_level_update"
  post "/webhooks/app/subscriptions/update", to: "webhooks#app_subscriptions_update"

  namespace :api do
    namespace :v1 do
      get "session", to: "sessions#show"
      get "dashboard", to: "dashboard#show"
      get "catalog", to: "catalog#show"
      get "review_queue", to: "review_queue#index"
      post "review_queue/bulk_confirm", to: "review_decisions#bulk_confirm"
      post "review_queue/bulk_reject", to: "review_decisions#bulk_reject"
      post "review_queue/:mapping_id/confirm", to: "review_decisions#confirm"
      post "review_queue/:mapping_id/reject", to: "review_decisions#reject"
      post "review_queue/:mapping_id/manual_match", to: "review_decisions#manual_match"
      get "merchants/catalog_sync_status", to: "merchants#catalog_sync_status"
      get "merchants/trial_status", to: "merchants#trial_status"
      post "billing", to: "billing#create"
      resources :suppliers, only: %i[index show create] do
        resources :mappings, only: :index, module: :suppliers
        resources :uploads, only: :show, module: :suppliers do
          member do
            get :status
          end
        end
        resources :feeds, only: %i[create show update], module: :suppliers do
          resources :uploads, only: :index, module: :feeds
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
