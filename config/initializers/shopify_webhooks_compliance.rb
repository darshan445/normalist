# frozen_string_literal: true

# Shopify app review requires:
# - 401 when HMAC is missing/invalid (not 500)
# - 200 when HMAC is valid
# See: https://shopify.dev/docs/apps/build/compliance/privacy-law-compliance
module ShopifyAppWebhookVerificationFix
  private

  def verify_request
    if shopify_hmac.blank?
      head(:unauthorized)
      return
    end

    data = request.raw_post
    unless hmac_valid?(data)
      ShopifyApp::Logger.debug("Webhook verification failed - HMAC invalid")
      head(:unauthorized)
      return
    end
  end
end

module ShopifyAppWebhooksControllerCompliance
  extend ActiveSupport::Concern

  included do
    rescue_from ShopifyAPI::Errors::InvalidWebhookError, with: :webhook_unauthorized
    rescue_from ShopifyAPI::Errors::NoWebhookHandler, with: :webhook_unauthorized
  end

  def webhook_unauthorized
    head(:unauthorized)
  end
end

def apply_shopify_webhook_compliance_patches!
  if defined?(ShopifyApp::WebhookVerification) &&
      !ShopifyApp::WebhookVerification.ancestors.include?(ShopifyAppWebhookVerificationFix)
    ShopifyApp::WebhookVerification.prepend(ShopifyAppWebhookVerificationFix)
  end

  if defined?(ShopifyApp::WebhooksController) &&
      !ShopifyApp::WebhooksController.included_modules.include?(ShopifyAppWebhooksControllerCompliance)
    ShopifyApp::WebhooksController.include(ShopifyAppWebhooksControllerCompliance)
  end
end

Rails.application.config.after_initialize { apply_shopify_webhook_compliance_patches! }
Rails.application.config.to_prepare { apply_shopify_webhook_compliance_patches! }
