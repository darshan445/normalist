# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::InventoryWriter do
  let(:merchant) do
    create(
      :merchant,
      platform: "shopify",
      platform_domain: "test-shop.myshopify.com",
      access_token: "shpat_test",
      location_id: "loc-1"
    )
  end
  let(:supplier) { create(:supplier, merchant: merchant) }
  let!(:mapping) do
    create(
      :mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_code: "SUP-1",
      status: "mapped",
      master_sku: "SKU-1",
      platform_inventory_id: "inv-99",
      quantity_behavior: "replace"
    )
  end
  let(:session) { instance_double(ShopifyAPI::Auth::Session) }
  let(:inventory_level) { instance_double(ShopifyAPI::InventoryLevel) }

  before do
    allow(merchant).to receive(:with_shopify_session).and_yield(session)
    allow(ShopifyAPI::InventoryLevel).to receive(:new).with(session: session).and_return(inventory_level)
    allow(inventory_level).to receive(:connect)
    allow(inventory_level).to receive(:set)
    allow(inventory_level).to receive(:adjust)
  end

  it "sets absolute available quantity at the merchant location using platform_inventory_id" do
    described_class.call(merchant: merchant, mapping: mapping, quantity: 42)

    expect(inventory_level).to have_received(:connect).with(
      inventory_item_id: "inv-99",
      location_id: "loc-1",
      relocate_if_necessary: false
    )
    expect(inventory_level).to have_received(:set).with(
      inventory_item_id: "inv-99",
      location_id: "loc-1",
      available: 42
    )
    expect(inventory_level).not_to have_received(:adjust)
  end

  it "adjusts available quantity when quantity_behavior is add" do
    mapping.update!(quantity_behavior: "add")

    described_class.call(merchant: merchant, mapping: mapping, quantity: 5)

    expect(inventory_level).to have_received(:adjust).with(
      inventory_item_id: "inv-99",
      location_id: "loc-1",
      available_adjustment: 5
    )
    expect(inventory_level).not_to have_received(:set)
  end

  it "raises NotReady when platform_inventory_id is missing" do
    mapping.update!(platform_inventory_id: nil)

    expect {
      described_class.call(merchant: merchant, mapping: mapping, quantity: 1)
    }.to raise_error(Shopify::InventoryWriter::NotReady, /missing platform_inventory_id/)
  end
end
