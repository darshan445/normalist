# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomersDataRequestJob do
  it "delegates to GDPR compliance handler" do
    merchant = create(:merchant, platform_domain: "test-store.myshopify.com")
    webhook = { "customer" => { "id" => 42 } }

    expect(Gdpr::CustomerDataCompliance).to receive(:handle_data_request).with(
      merchant: merchant,
      webhook: webhook
    )

    described_class.perform_now(shop_domain: merchant.platform_domain, webhook: webhook)
  end
end
