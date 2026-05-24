# frozen_string_literal: true

module Api
  module V1
    class BillingController < BaseController
      skip_before_action :check_billing_access

      def create
        merchant = current_merchant

        if merchant.subscribed?
          render json: { error: "already_subscribed", message: "You already have an active subscription." },
                 status: :unprocessable_entity
          return
        end

        session = Merchant.retrieve_by_shopify_domain(merchant.platform_domain)
        unless session
          render json: { error: "no_session", message: "Reconnect the app from Shopify Admin and try again." },
                 status: :unauthorized
          return
        end

        confirmation_url = Billing::ChargeCreator.call(merchant: merchant, session: session)
        render json: { confirmation_url: confirmation_url }
      rescue Billing::ChargeCreationError => e
        render json: { error: "charge_failed", message: e.user_message },
               status: :unprocessable_entity
      end
    end
  end
end
