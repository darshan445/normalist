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
  let(:graphql_client) { instance_double(Shopify::GraphqlClient) }

  before do
    allow(Shopify::GraphqlClient).to receive(:new).with(session).and_return(graphql_client)
  end

  it "returns a friendly message when Shopify returns an auth error" do
    allow(graphql_client).to receive(:mutate!).and_raise(
      Shopify::GraphqlClient::UserErrors.new(
        [{ "message" => "[API] Invalid API key or access token (unrecognized login or wrong password)" }]
      )
    )

    expect {
      described_class.call(merchant: merchant, session: session)
    }.to raise_error(Billing::ChargeCreationError) do |e|
      expect(e.user_message).to include("Reopen NormaList from Shopify Admin")
    end
  end

  it "returns the confirmation URL from GraphQL" do
    allow(graphql_client).to receive(:mutate!).and_return(
      {
        "confirmationUrl" => "https://test.myshopify.com/admin/charges/confirm",
        "appSubscription" => { "id" => "gid://shopify/AppSubscription/123" }
      }
    )

    url = described_class.call(merchant: merchant, session: session)
    expect(url).to eq("https://test.myshopify.com/admin/charges/confirm")
  end
end
