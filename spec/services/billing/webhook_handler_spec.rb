# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::WebhookHandler do
  let!(:plan) do
    Plan.find_or_create_by!(key: "starter") do |p|
      p.name = "Starter"
      p.price = 14
      p.interval = "monthly"
      p.active = true
    end
  end

  let(:merchant_a) do
    create(
      :merchant,
      platform: "shopify",
      platform_domain: "store-a.myshopify.com",
      access_token: "shpat_a",
      plan_status: "active"
    )
  end

  let(:merchant_b) do
    create(
      :merchant,
      platform: "shopify",
      platform_domain: "store-b.myshopify.com",
      access_token: "shpat_b",
      plan_status: "trialing"
    )
  end

  let(:charge_id) { "888999000" }

  let!(:subscription_a) do
    Subscription.create!(
      merchant: merchant_a,
      plan: plan,
      shopify_charge_id: charge_id,
      status: "active",
      price: 14,
      interval: "monthly",
      activated_at: Time.current,
      billing_on: 1.month.from_now
    )
  end

  it "updates subscription status only for the webhook merchant" do
    payload = {
      "app_subscription" => {
        "admin_graphql_api_id" => "gid://shopify/AppSubscription/#{charge_id}",
        "status" => "frozen",
        "billing_on" => subscription_a.billing_on
      }
    }

    described_class.call(merchant: merchant_b, payload: payload)

    expect(subscription_a.reload.status).to eq("active")
    expect(merchant_b.reload.plan_status).to eq("trialing")
  end

  it "freezes the matching merchant subscription" do
    payload = {
      "app_subscription" => {
        "admin_graphql_api_id" => "gid://shopify/AppSubscription/#{charge_id}",
        "status" => "frozen",
        "billing_on" => subscription_a.billing_on
      }
    }

    described_class.call(merchant: merchant_a, payload: payload)

    expect(subscription_a.reload.status).to eq("frozen")
    expect(merchant_a.reload.plan_status).to eq("frozen")
  end
end
