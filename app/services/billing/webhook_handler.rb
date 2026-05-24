# frozen_string_literal: true

module Billing
  class WebhookHandler
    def self.call(merchant:, payload:)
      new(merchant, payload).handle
    end

    def initialize(merchant, payload)
      @merchant = merchant
      @payload = payload
    end

    def handle
      subscription_data = subscription_payload
      charge_id = extract_charge_id(subscription_data)
      status = subscription_data["status"].to_s.downcase

      subscription = Subscription.find_by(shopify_charge_id: charge_id)

      unless subscription
        if status == "active"
          activate_from_webhook(charge_id)
        else
          Rails.logger.warn(
            "[WebhookHandler] subscription not found charge_id=#{charge_id} status=#{status}"
          )
        end
        return
      end

      case status
      when "active"
        handle_active(subscription)
      when "frozen"
        handle_frozen(subscription)
      when "cancelled"
        handle_cancelled(subscription)
      end
    end

    private

    def subscription_payload
      @payload["app_subscription"].presence || @payload
    end

    def extract_charge_id(data)
      gid = data["admin_graphql_api_id"].to_s
      return gid.split("/").last if gid.include?("/")

      data["id"].to_s
    end

    def activate_from_webhook(charge_id)
      return if charge_id.blank?

      session = Merchant.retrieve_by_shopify_domain(@merchant.platform_domain)
      unless session
        Rails.logger.warn(
          "[WebhookHandler] no session for activation merchant=#{@merchant.id}"
        )
        return
      end

      result = ChargeActivator.call(
        merchant: @merchant,
        session: session,
        charge_id: charge_id
      )

      unless result[:success]
        Rails.logger.warn(
          "[WebhookHandler] activation failed merchant=#{@merchant.id} " \
          "charge_id=#{charge_id} status=#{result[:status]}"
        )
      end
    rescue StandardError => e
      Rails.logger.error(
        "[WebhookHandler] activation error merchant=#{@merchant.id} " \
        "charge_id=#{charge_id} error=#{e.message}"
      )
    end

    def handle_active(subscription)
      was_frozen = subscription.frozen?

      subscription.update!(
        status: "active",
        frozen_at: nil,
        billing_on: parse_date(subscription_payload["billing_on"]),
        shopify_payload: subscription_payload
      )

      @merchant.update!(plan_status: "active")

      return unless was_frozen

      Billing::PlanChangeRecorder.call(
        merchant: @merchant,
        subscription: subscription,
        to_plan: subscription.plan.key,
        reason: "payment_resumed",
        initiated_by: "system"
      )
    end

    def handle_frozen(subscription)
      subscription.update!(
        status: "frozen",
        frozen_at: Time.current,
        shopify_payload: subscription_payload
      )

      @merchant.update!(plan_status: "frozen")

      Billing::PlanChangeRecorder.call(
        merchant: @merchant,
        subscription: subscription,
        to_plan: subscription.plan.key,
        reason: "payment_failed",
        initiated_by: "system"
      )
    end

    def handle_cancelled(subscription)
      if subscription.billing_on.present? && subscription.billing_on.end_of_day >= Time.current
        subscription.update!(
          cancelled_at: subscription.cancelled_at || Time.current,
          shopify_payload: subscription_payload
        )

        @merchant.update!(plan_status: "cancelled")

        Billing::PlanChangeRecorder.call(
          merchant: @merchant,
          subscription: subscription,
          to_plan: subscription.plan.key,
          reason: "cancel",
          initiated_by: "merchant"
        )
        return
      end

      subscription.update!(
        status: "cancelled",
        cancelled_at: subscription.cancelled_at || Time.current,
        shopify_payload: subscription_payload
      )

      @merchant.update!(plan_status: "cancelled")

      Billing::PlanChangeRecorder.call(
        merchant: @merchant,
        subscription: subscription,
        to_plan: "cancelled",
        reason: "cancel",
        initiated_by: "merchant"
      )
    end

    def parse_date(date_string)
      return nil if date_string.blank?

      Time.zone.parse(date_string.to_s)
    end
  end
end
