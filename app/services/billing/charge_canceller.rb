# frozen_string_literal: true

module Billing
  class ChargeCanceller
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

      ShopifyAPI::RecurringApplicationCharge.delete(
        id: subscription.shopify_charge_id,
        session: @session
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
    rescue ShopifyAPI::Errors::HttpResponseError => e
      message = user_message_for(e)
      Rails.logger.error(
        "[ChargeCanceller] cancel failed merchant=#{@merchant.id} error=#{e.message}"
      )
      raise ChargeCancellationError.new(message, original: e)
    end

    private

    def user_message_for(error)
      body = parse_error_body(error)
      detail = body.dig("errors", "base")
      detail = detail.first if detail.is_a?(Array)
      detail = detail.presence || body.dig("errors")&.to_s.presence

      detail.presence || "Could not cancel subscription. Please try again or contact support."
    end

    def parse_error_body(error)
      response = error.response
      return {} unless response.respond_to?(:body)

      body = response.body
      return body if body.is_a?(Hash)

      JSON.parse(body.to_s)
    rescue JSON::ParserError
      {}
    end
  end
end
