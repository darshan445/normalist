# frozen_string_literal: true

module BillingGate
  extend ActiveSupport::Concern

  included do
    before_action :check_billing_access
  end

  private

  def check_billing_access
    return if skip_billing_check?

    merchant = current_merchant
    return if merchant.nil? || merchant.has_access?

    render json: {
      error: "subscription_required",
      message: billing_message(merchant),
      billing_url: billing_url(merchant),
      trial_expired: merchant.trial_expired?,
      plan_status: merchant.plan_status
    }, status: :payment_required
  end

  def skip_billing_check?
    trial_status_endpoint? || session_endpoint?
  end

  def trial_status_endpoint?
    controller_path == "api/v1/merchants" && action_name == "trial_status"
  end

  def session_endpoint?
    controller_path == "api/v1/sessions" && action_name == "show"
  end

  def billing_message(merchant)
    if merchant.trial_expired?
      "Your 14-day free trial has ended. Subscribe to continue using NormaList."
    elsif merchant.frozen?
      "Your payment failed. Please update your billing details."
    else
      "Please subscribe to use NormaList."
    end
  end

  def billing_url(merchant)
    shop = merchant.platform_domain
    "#{frontend_base_url}/subscription?shop=#{CGI.escape(shop.to_s)}"
  end

  def frontend_base_url
    raw = ENV.fetch("FRONTEND_URL").to_s.strip.delete_suffix("/")
    raw.start_with?("http") ? raw : "https://#{raw}"
  end
end
