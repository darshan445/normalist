# frozen_string_literal: true

module BillingSession
  extend ActiveSupport::Concern

  included do
    before_action :require_billing_session!
  end

  private

  def require_billing_session!
    shop = ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    unless shop
      return render json: { error: "missing_shop", message: "Shop parameter is required" },
                    status: :bad_request
    end

    @current_merchant = Merchant.find_by(platform_domain: shop)
    @current_shopify_session = Merchant.retrieve_by_shopify_domain(shop)

    return if @current_merchant&.shopify_connected? && @current_shopify_session

    redirect_to "/login?shop=#{CGI.escape(shop)}", allow_other_host: true
  end

  def current_merchant
    @current_merchant
  end

  def current_shopify_session
    @current_shopify_session
  end
end
