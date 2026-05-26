# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomersRedactJob do
  it "delegates to GDPR compliance handler" do
    merchant = create(:merchant, platform_domain: "test-store.myshopify.com")
    webhook = { "customer" => { "id" => 99 } }

    expect(Gdpr::CustomerDataCompliance).to receive(:handle_redact).with(
      merchant: merchant,
      webhook: webhook
    )

    described_class.perform_now(shop_domain: merchant.platform_domain, webhook: webhook)
  end
end
