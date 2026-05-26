# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::ChargeActivator do
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

  let(:shared_charge_id) { "555666777" }
  let(:session_b) { instance_double(ShopifyAPI::Auth::Session) }

  let!(:subscription_a) do
    Subscription.create!(
      merchant: merchant_a,
      plan: plan,
      shopify_charge_id: shared_charge_id,
      status: "active",
      price: 14,
      interval: "monthly",
      activated_at: Time.current
    )
  end

  it "reuses an existing subscription only for the same merchant" do
    session_a = instance_double(ShopifyAPI::Auth::Session)

    expect(ShopifyAPI::RecurringApplicationCharge).not_to receive(:find)

    result = described_class.call(
      merchant: merchant_a,
      session: session_a,
      charge_id: shared_charge_id
    )

    expect(result[:success]).to be true
    expect(result[:subscription]).to eq(subscription_a)
  end

  it "does not activate merchant B using merchant A subscription" do
    charge = instance_double(
      ShopifyAPI::RecurringApplicationCharge,
      id: shared_charge_id,
      status: "active",
      price: 14,
      billing_on: 1.month.from_now.to_date.to_s,
      name: "NormaList",
      trial_days: 0,
      confirmation_url: "https://example.com",
      return_url: "https://example.com",
      test: true
    )

    expect(ShopifyAPI::RecurringApplicationCharge).to receive(:find).with(
      id: shared_charge_id,
      session: session_b
    ).and_return(charge)

    expect {
      described_class.call(
        merchant: merchant_b,
        session: session_b,
        charge_id: shared_charge_id
      )
    }.to raise_error(ActiveRecord::RecordInvalid)

    expect(merchant_b.reload.plan_status).to eq("trialing")
    expect(merchant_b.subscriptions).to be_empty
    expect(subscription_a.reload.merchant_id).to eq(merchant_a.id)
  end
end
