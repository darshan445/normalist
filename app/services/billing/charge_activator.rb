# frozen_string_literal: true

module Billing
  class ChargeActivator
    SUBSCRIPTION_QUERY = <<~GRAPHQL
      query AppSubscription($id: ID!) {
        node(id: $id) {
          ... on AppSubscription {
            id
            name
            status
            test
            currentPeriodEnd
            lineItems {
              plan {
                pricingDetails {
                  ... on AppRecurringPricing {
                    price {
                      amount
                    }
                    interval
                  }
                }
              }
            }
          }
        }
      }
    GRAPHQL

    def self.call(merchant:, session:, charge_id:)
      new(merchant, session, charge_id).activate
    end

    def initialize(merchant, session, charge_id)
      @merchant = merchant
      @session = session
      @charge_id = charge_id
    end

    ACTIVATABLE_STATUSES = %w[ACTIVE ACCEPTED PENDING].freeze

    def activate
      charge_id = Shopify::Gid.numeric_id(@charge_id)
      existing = @merchant.subscriptions.find_by(shopify_charge_id: charge_id)
      if existing&.active?
        @merchant.update!(plan_status: "active") unless @merchant.subscribed?
        return { success: true, subscription: existing }
      end

      subscription = fetch_subscription(charge_id)

      unless ACTIVATABLE_STATUSES.include?(subscription[:status].to_s.upcase)
        Rails.logger.warn(
          "[ChargeActivator] not activatable " \
          "merchant=#{@merchant.id} " \
          "status=#{subscription[:status]}"
        )
        return { success: false, status: subscription[:status] }
      end

      plan = Plan.find_by!(key: "starter")

      record = Subscription.create!(
        merchant: @merchant,
        plan: plan,
        shopify_charge_id: charge_id,
        status: "active",
        price: subscription[:price],
        interval: "monthly",
        trial_days: 0,
        trial_ends_at: nil,
        activated_at: Time.current,
        billing_on: subscription[:billing_on],
        shopify_payload: subscription[:payload]
      )

      @merchant.update!(plan_status: "active")

      Billing::PlanChangeRecorder.call(
        merchant: @merchant,
        subscription: record,
        to_plan: plan.key,
        reason: "upgrade",
        initiated_by: "merchant"
      )

      Rails.logger.info(
        "[ChargeActivator] subscription activated " \
        "merchant=#{@merchant.id} " \
        "subscription=#{record.id}"
      )

      { success: true, subscription: record }
    rescue Shopify::GraphqlClient::Error => e
      Rails.logger.warn(
        "[ChargeActivator] subscription lookup failed " \
        "merchant=#{@merchant.id} charge_id=#{Shopify::Gid.numeric_id(@charge_id)} error=#{e.message}"
      )
      { success: false, status: "not_found" }
    end

    private

    def fetch_subscription(charge_id)
      client = Shopify::GraphqlClient.new(@session)
      body = client.query(
        query: SUBSCRIPTION_QUERY,
        variables: { id: Shopify::Gid.app_subscription(charge_id) }
      )
      node = body.dig("data", "node")
      raise Shopify::GraphqlClient::Error, "App subscription not found" if node.blank?

      pricing = node.dig("lineItems", 0, "plan", "pricingDetails")
      price = pricing&.dig("price", "amount").to_f

      {
        status: node["status"],
        price: price,
        billing_on: parse_date(node["currentPeriodEnd"]),
        payload: node
      }
    end

    def parse_date(date_string)
      return nil if date_string.blank?

      Time.zone.parse(date_string.to_s)
    end
  end
end
