# frozen_string_literal: true

require "rails_helper"

RSpec.describe Gdpr::CustomerDataCompliance do
  let(:merchant) { create(:merchant, platform_domain: "test-store.myshopify.com") }

  it "logs data request with customer id and no export action" do
    webhook = {
      "customer" => { "id" => 12_345, "email" => "buyer@example.com" },
      "orders_requested" => [ 99 ]
    }

    expect(Rails.logger).to receive(:info).with(
      a_string_including(
        "customers/data_request",
        "merchant=#{merchant.id}",
        "customer_ids=12345",
        "no_customer_data_stored"
      )
    )

    described_class.handle_data_request(merchant: merchant, webhook: webhook)
  end

  it "logs redact with customer id and no deletion action" do
    webhook = {
      "customer" => { "id" => 67_890 },
      "orders_to_redact" => [ 1, 2 ]
    }

    expect(Rails.logger).to receive(:info).with(
      a_string_including(
        "customers/redact",
        "merchant=#{merchant.id}",
        "customer_ids=67890",
        "no_customer_data_stored"
      )
    )

    described_class.handle_redact(merchant: merchant, webhook: webhook)
  end
end
