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
  let(:graphql_client) { instance_double(Shopify::GraphqlClient) }

  before do
    allow(merchant).to receive(:with_shopify_session).and_yield(session)
    allow(Shopify::GraphqlClient).to receive(:new).with(session).and_return(graphql_client)
    allow(graphql_client).to receive(:mutate!).and_return({})
  end

  it "sets absolute available quantity using GraphQL inventorySetQuantities" do
    described_class.call(merchant: merchant, mapping: mapping, quantity: 42)

    expect(graphql_client).to have_received(:mutate!).with(
      hash_including(payload_key: "inventoryActivate")
    )
    expect(graphql_client).to have_received(:mutate!).with(
      hash_including(
        payload_key: "inventorySetQuantities",
        variables: hash_including(
          input: hash_including(
            ignoreCompareQuantity: true,
            quantities: [
              hash_including(
                inventoryItemId: "gid://shopify/InventoryItem/inv-99",
                locationId: "gid://shopify/Location/loc-1",
                quantity: 42
              )
            ]
          )
        )
      )
    )
  end

  it "adjusts available quantity when quantity_behavior is add" do
    mapping.update!(quantity_behavior: "add")

    allow(graphql_client).to receive(:query).and_return(
      { "data" => { "inventoryItem" => { "inventoryLevel" => { "quantities" => [{ "quantity" => 10 }] } } } }
    )

    described_class.call(merchant: merchant, mapping: mapping, quantity: 5)

    expect(graphql_client).to have_received(:query).with(
      hash_including(variables: hash_including(inventoryItemId: "gid://shopify/InventoryItem/inv-99"))
    )
    expect(graphql_client).to have_received(:mutate!).with(
      hash_including(
        payload_key: "inventoryAdjustQuantities",
        variables: hash_including(
          input: hash_including(
            changes: [
              hash_including(
                delta: 5,
                changeFromQuantity: 10,
                inventoryItemId: "gid://shopify/InventoryItem/inv-99",
                locationId: "gid://shopify/Location/loc-1"
              )
            ]
          )
        )
      )
    )
  end

  it "raises NotReady when platform_inventory_id is missing" do
    mapping.update!(platform_inventory_id: nil)

    expect {
      described_class.call(merchant: merchant, mapping: mapping, quantity: 1)
    }.to raise_error(Shopify::InventoryWriter::NotReady, /missing platform_inventory_id/)
  end
end
