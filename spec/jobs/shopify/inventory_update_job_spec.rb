# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::InventoryUpdateJob do
  let(:merchant) do
    create(
      :merchant,
      platform: "shopify",
      platform_domain: "test-shop.myshopify.com",
      access_token: "token",
      location_id: "loc-1"
    )
  end
  let(:supplier) { create(:supplier, merchant: merchant) }
  let(:upload) { create(:supplier_upload, merchant: merchant, supplier: supplier) }
  let!(:variant) do
    create(
      :variant,
      merchant: merchant,
      master_sku: "SKU-1",
      platform_inventory_id: "inv-1"
    )
  end
  let!(:mapping) do
    create(
      :mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_upload: upload,
      supplier_code: "SUP-1",
      status: "mapped",
      master_sku: "SKU-1",
      platform_inventory_id: "inv-1",
      pending_quantity: 20
    )
  end

  before do
    allow(Shopify::InventoryWriter).to receive(:call).and_return(true)
  end

  it "calls InventoryWriter and clears pending_quantity after a successful sync" do
    described_class.perform_now(merchant.id, upload.id, mapping.id)

    expect(Shopify::InventoryWriter).to have_received(:call).with(
      merchant: merchant,
      mapping: mapping,
      quantity: 20
    )
    expect(mapping.reload.pending_quantity).to be_nil
  end

  it "clears pending_quantity when the platform is not connected" do
    merchant.update!(access_token: nil)

    described_class.perform_now(merchant.id, upload.id, mapping.id)

    expect(mapping.reload.pending_quantity).to be_nil
  end

  it "does nothing when pending_quantity is blank" do
    mapping.update!(pending_quantity: nil)

    described_class.perform_now(merchant.id, upload.id, mapping.id)

    expect(Shopify::InventoryWriter).not_to have_received(:call)
    expect(mapping.reload.pending_quantity).to be_nil
  end

  it "keeps pending_quantity when Shopify returns a write error for Sidekiq retry" do
    allow(Shopify::InventoryWriter).to receive(:call)
      .and_raise(Shopify::InventoryWriter::WriteError, "rate limited")

    described_class.perform_now(merchant.id, upload.id, mapping.id) rescue nil

    expect(mapping.reload.pending_quantity).to eq(20)
  end
end
