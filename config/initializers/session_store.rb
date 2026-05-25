# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Rails.application.config.session_store(:cookie_store, key: "_normalist_session", expire_after: 14.days)

# shopify_app OAuth (/login, /auth/shopify/callback) uses ERB views with flash and
# encrypted cookies. Rails api_only omits these middlewares by default.
if Rails.application.config.api_only
  Rails.application.config.middleware.use ActionDispatch::Cookies
  Rails.application.config.middleware.use(
    ActionDispatch::Session::CookieStore,
    Rails.application.config.session_options
  )
  Rails.application.config.middleware.use ActionDispatch::Flash
  Rails.application.config.middleware.use Rack::MethodOverride
end
