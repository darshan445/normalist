# frozen_string_literal: true

module Billing
  class ChargeCanceller
    CANCEL_MUTATION = <<~GRAPHQL
      mutation AppSubscriptionCancel($id: ID!) {
        appSubscriptionCancel(id: $id) {
          userErrors {
            field
            message
          }
          appSubscription {
            id
            status
          }
        }
      }
    GRAPHQL

    def self.call(merchant:, session:)
      new(merchant, session).cancel
    end

    def initialize(merchant, session)
      @merchant = merchant
      @session = session
    end

    def cancel
      subscription = @merchant.active_subscription

      unless subscription
        if @merchant.cancellation_pending? || @merchant.cancelled?
          return { success: true, already_cancelled: true }
        end

        return { success: false, error: "no_active_subscription" }
      end

      if subscription.cancelled_at.present?
        return { success: true, already_cancelled: true }
      end

      client = Shopify::GraphqlClient.new(@session)
      client.mutate!(
        query: CANCEL_MUTATION,
        variables: { id: Shopify::Gid.app_subscription(subscription.shopify_charge_id) },
        payload_key: "appSubscriptionCancel"
      )

      subscription.update!(
        cancelled_at: Time.current
      )

      @merchant.update!(plan_status: "cancelled")

      Billing::PlanChangeRecorder.call(
        merchant: @merchant,
        subscription: subscription,
        to_plan: subscription.plan.key,
        reason: "cancel",
        initiated_by: "merchant",
        note: "Cancelled at period end"
      )

      Rails.logger.info(
        "[ChargeCanceller] subscription cancelled " \
        "merchant=#{@merchant.id} " \
        "subscription=#{subscription.id}"
      )

      { success: true, subscription: subscription }
    rescue Shopify::GraphqlClient::UserErrors => e
      message = user_message_for(e.message)
      Rails.logger.error(
        "[ChargeCanceller] cancel failed merchant=#{@merchant.id} error=#{e.message}"
      )
      raise ChargeCancellationError.new(message, original: e)
    rescue Shopify::GraphqlClient::Error => e
      message = user_message_for(e.message)
      Rails.logger.error(
        "[ChargeCanceller] cancel failed merchant=#{@merchant.id} error=#{e.message}"
      )
      raise ChargeCancellationError.new(message, original: e)
    rescue ShopifyAPI::Errors::HttpResponseError => e
      message = user_message_for(e.message)
      Rails.logger.error(
        "[ChargeCanceller] cancel failed merchant=#{@merchant.id} error=#{e.message}"
      )
      raise ChargeCancellationError.new(message, original: e)
    end

    private

    def user_message_for(detail)
      detail.presence || "Could not cancel subscription. Please try again or contact support."
    end
  end
end
