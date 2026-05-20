# frozen_string_literal: true

# Embedded app UI (FRONTEND_URL) posts OAuth to HOST; Origin and base_url differ by design.
# CSRF token is still verified — only the Origin header check is relaxed in production.
if Rails.env.production?
  Rails.application.config.action_controller.forgery_protection_origin_check = false
end
