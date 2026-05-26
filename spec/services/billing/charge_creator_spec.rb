# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::ChargeCreator do
  let!(:plan) do
    Plan.find_or_create_by!(key: "starter") do |p|
      p.name = "Starter"
      p.price = 29
      p.active = true
    end
  end
  let(:merchant) do
    create(
      :merchant,
      platform: "shopify",
      platform_domain: "test.myshopify.com",
      access_token: "token"
    )
  end
  let(:session) { instance_double(ShopifyAPI::Auth::Session, shop: merchant.platform_domain) }

  def build_http_error(body_hash)
    response = instance_double(
      ShopifyAPI::Clients::HttpResponse,
      body: body_hash,
      code: 401
    )
    ShopifyAPI::Errors::HttpResponseError.new(response: response)
  end

  it "returns a friendly message when Shopify errors is a string" do
    charge = instance_double(ShopifyAPI::RecurringApplicationCharge)
    allow(ShopifyAPI::RecurringApplicationCharge).to receive(:new).with(session: session).and_return(charge)
    allow(charge).to receive(:name=)
    allow(charge).to receive(:price=)
    allow(charge).to receive(:trial_days=)
    allow(charge).to receive(:test=)
    allow(charge).to receive(:return_url=)
    allow(charge).to receive(:save!).and_raise(
      build_http_error(
        { "errors" => "[API] Invalid API key or access token (unrecognized login or wrong password)" }
      )
    )

    expect {
      described_class.call(merchant: merchant, session: session)
    }.to raise_error(Billing::ChargeCreationError) do |e|
      expect(e.user_message).to include("Reopen NormaList from Shopify Admin")
    end
  end
end
