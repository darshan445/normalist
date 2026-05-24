# frozen_string_literal: true

class BillingController < ApplicationController
  include BillingSession

  # Legacy GET /billing — do not create charges here (Next.js prefetches link URLs in iframe).
  def show
    redirect_to frontend_pricing_url,
                allow_other_host: true
  end

  def callback
    merchant = current_merchant
    charge_id = params[:charge_id]

    if charge_id.blank?
      redirect_to billing_path(shop: merchant.platform_domain),
                  alert: "Something went wrong. Please try again.",
                  allow_other_host: true
      return
    end

    result = Billing::ChargeActivator.call(
      merchant: merchant,
      session: current_shopify_session,
      charge_id: charge_id
    )

    if result[:success]
      redirect_to frontend_root_url,
                  allow_other_host: true
    else
      redirect_to frontend_pricing_url,
                  allow_other_host: true
    end
  end

  private

  def frontend_root_url
    raw = ENV.fetch("FRONTEND_URL").to_s.strip.delete_suffix("/")
    url = raw.start_with?("http") ? raw : "https://#{raw}"
    shop = current_merchant.platform_domain
    "#{url}/?shop=#{CGI.escape(shop)}"
  end

  def frontend_pricing_url(error: nil)
    raw = ENV.fetch("FRONTEND_URL").to_s.strip.delete_suffix("/")
    url = raw.start_with?("http") ? raw : "https://#{raw}"
    shop = current_merchant.platform_domain
    params = { shop: shop }
    params[:billing_error] = error if error.present?
    "#{url}/subscription?#{params.to_query}"
  end
end
