# frozen_string_literal: true

module Billing
  class ChargeActivator
    def self.call(merchant:, session:, charge_id:)
      new(merchant, session, charge_id).activate
    end

    def initialize(merchant, session, charge_id)
      @merchant = merchant
      @session = session
      @charge_id = charge_id
    end

    ACTIVATABLE_STATUSES = %w[accepted active].freeze

    def activate
      existing = @merchant.subscriptions.find_by(shopify_charge_id: @charge_id.to_s)
      if existing&.active?
        @merchant.update!(plan_status: "active") unless @merchant.subscribed?
        return { success: true, subscription: existing }
      end

      charge = ShopifyAPI::RecurringApplicationCharge.find(
        id: @charge_id,
        session: @session
      )

      unless ACTIVATABLE_STATUSES.include?(charge.status.to_s)
        Rails.logger.warn(
          "[ChargeActivator] not activatable " \
          "merchant=#{@merchant.id} " \
          "status=#{charge.status}"
        )
        return { success: false, status: charge.status }
      end

      plan = Plan.find_by!(key: "starter")

      subscription = Subscription.create!(
        merchant: @merchant,
        plan: plan,
        shopify_charge_id: charge.id.to_s,
        status: "active",
        price: charge.price.to_f,
        interval: "monthly",
        trial_days: 0,
        trial_ends_at: nil,
        activated_at: Time.current,
        billing_on: parse_date(charge.billing_on),
        shopify_payload: charge_attributes(charge)
      )

      @merchant.update!(plan_status: "active")

      Billing::PlanChangeRecorder.call(
        merchant: @merchant,
        subscription: subscription,
        to_plan: plan.key,
        reason: "upgrade",
        initiated_by: "merchant"
      )

      Rails.logger.info(
        "[ChargeActivator] subscription activated " \
        "merchant=#{@merchant.id} " \
        "subscription=#{subscription.id}"
      )

      { success: true, subscription: subscription }
    end

    private

    def charge_attributes(charge)
      {
        "id" => charge.id,
        "name" => charge.name,
        "price" => charge.price,
        "status" => charge.status,
        "billing_on" => charge.billing_on,
        "trial_days" => charge.trial_days,
        "confirmation_url" => charge.confirmation_url,
        "return_url" => charge.return_url,
        "test" => charge.test
      }
    end

    def parse_date(date_string)
      return nil if date_string.blank?

      Time.zone.parse(date_string.to_s)
    end
  end
end
