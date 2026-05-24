# frozen_string_literal: true

module Api
  module V1
    class BillingController < BaseController
      skip_before_action :check_billing_access

      def create
        merchant = current_merchant

        if merchant.access_subscription
          render json: {
            error: "already_subscribed",
            message: "You already have an active subscription."
          }, status: :unprocessable_entity
          return
        end

        session = shopify_session_for(merchant)
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

      def destroy
        merchant = current_merchant

        unless merchant.can_cancel_subscription?
          render json: {
            error: "not_subscribed",
            message: merchant.cancellation_pending? ?
              "Your subscription is already scheduled to cancel." :
              "No active subscription to cancel."
          }, status: :unprocessable_entity
          return
        end

        session = shopify_session_for(merchant)
        unless session
          render json: { error: "no_session", message: "Reconnect the app from Shopify Admin and try again." },
                 status: :unauthorized
          return
        end

        result = Billing::ChargeCanceller.call(merchant: merchant, session: session)

        if result[:success]
          render json: { success: true, cancelled: true }
        else
          render json: {
            error: result[:error],
            message: "No active subscription to cancel."
          }, status: :unprocessable_entity
        end
      rescue Billing::ChargeCancellationError => e
        render json: { error: "cancel_failed", message: e.user_message },
               status: :unprocessable_entity
      end

      private

      def shopify_session_for(merchant)
        Merchant.retrieve_by_shopify_domain(merchant.platform_domain)
      end
    end
  end
end
