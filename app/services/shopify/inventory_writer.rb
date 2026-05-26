# frozen_string_literal: true

module Shopify
  # Writes supplier quantities to Shopify using the GraphQL Admin API.
  # Uses mapping.platform_inventory_id (Shopify inventory_item_id), not the Variant API.
  class InventoryWriter
    NotReady = Class.new(StandardError)
    WriteError = Class.new(StandardError)

    ACTIVATE_MUTATION = <<~GRAPHQL
      mutation InventoryActivate(
        $inventoryItemId: ID!,
        $locationId: ID!,
        $idempotencyKey: String!
      ) {
        inventoryActivate(
          inventoryItemId: $inventoryItemId,
          locationId: $locationId
        ) @idempotent(key: $idempotencyKey) {
          userErrors {
            field
            message
          }
          inventoryLevel {
            id
          }
        }
      }
    GRAPHQL

    SET_MUTATION = <<~GRAPHQL
      mutation InventorySetQuantities(
        $input: InventorySetQuantitiesInput!,
        $idempotencyKey: String!
      ) {
        inventorySetQuantities(input: $input) @idempotent(key: $idempotencyKey) {
          userErrors {
            field
            message
          }
          inventoryAdjustmentGroup {
            createdAt
          }
        }
      }
    GRAPHQL

    ADJUST_MUTATION = <<~GRAPHQL
      mutation InventoryAdjustQuantities(
        $input: InventoryAdjustQuantitiesInput!,
        $idempotencyKey: String!
      ) {
        inventoryAdjustQuantities(input: $input) @idempotent(key: $idempotencyKey) {
          userErrors {
            field
            message
          }
          inventoryAdjustmentGroup {
            createdAt
          }
        }
      }
    GRAPHQL

    def self.call(merchant:, mapping:, quantity:)
      new(merchant: merchant, mapping: mapping, quantity: quantity).call
    end

    def initialize(merchant:, mapping:, quantity:)
      @merchant = merchant
      @mapping = mapping
      @quantity = quantity.to_i
    end

    def call
      raise NotReady, "merchant is not connected to Shopify" unless @merchant.shopify_connected?

      inventory_item_id = inventory_item_id_for_mapping
      raise NotReady, "missing platform_inventory_id" if inventory_item_id.blank?

      location_id = resolve_location_id!
      raise NotReady, "no Shopify location available" if location_id.blank?

      @merchant.with_shopify_session do |session|
        client = GraphqlClient.new(session)
        ensure_activated!(client, inventory_item_id, location_id)
        apply_quantity!(client, inventory_item_id, location_id)
      end

      true
    rescue GraphqlClient::UserErrors => e
      raise WriteError, "Shopify inventory update failed: #{e.message}"
    rescue GraphqlClient::Error => e
      raise WriteError, "Shopify inventory update failed: #{e.message}"
    rescue ShopifyAPI::Errors::HttpResponseError => e
      raise WriteError, "Shopify inventory update failed: #{e.message}"
    end

    private

    def inventory_item_id_for_mapping
      @mapping.platform_inventory_id.presence ||
        @merchant.variants.active.find_by(master_sku: @mapping.master_sku)&.platform_inventory_id
    end

    def resolve_location_id!
      return @merchant.location_id if @merchant.location_id.present?

      @merchant.with_shopify_session do |session|
        location_id = PrimaryLocation.call(session: session)
        next unless location_id

        @merchant.update!(location_id: location_id)
        location_id
      end
    end

    def ensure_activated!(client, inventory_item_id, location_id)
      client.mutate!(
        query: ACTIVATE_MUTATION,
        variables: {
          inventoryItemId: Gid.inventory_item(inventory_item_id),
          locationId: Gid.location(location_id),
          idempotencyKey: SecureRandom.uuid
        },
        payload_key: "inventoryActivate"
      )
    rescue GraphqlClient::UserErrors => e
      # Already activated at this location is a common, non-fatal case.
      Rails.logger.info(
        "[Shopify::InventoryWriter] activate skipped inventory_item=#{inventory_item_id} " \
        "location=#{location_id}: #{e.message}"
      )
    end

    def apply_quantity!(client, inventory_item_id, location_id)
      if @mapping.quantity_behavior == "add"
        adjust_quantity!(client, inventory_item_id, location_id)
      else
        set_quantity!(client, inventory_item_id, location_id)
      end
    end

    def set_quantity!(client, inventory_item_id, location_id)
      client.mutate!(
        query: SET_MUTATION,
        variables: {
          input: {
            name: "available",
            reason: "correction",
            referenceDocumentUri: "normalist://inventory-sync",
            ignoreCompareQuantity: true,
            quantities: [
              {
                inventoryItemId: Gid.inventory_item(inventory_item_id),
                locationId: Gid.location(location_id),
                quantity: @quantity
              }
            ]
          },
          idempotencyKey: SecureRandom.uuid
        },
        payload_key: "inventorySetQuantities"
      )
    end

    def adjust_quantity!(client, inventory_item_id, location_id)
      client.mutate!(
        query: ADJUST_MUTATION,
        variables: {
          input: {
            name: "available",
            reason: "correction",
            referenceDocumentUri: "normalist://inventory-sync",
            changes: [
              {
                delta: @quantity,
                inventoryItemId: Gid.inventory_item(inventory_item_id),
                locationId: Gid.location(location_id)
              }
            ]
          },
          idempotencyKey: SecureRandom.uuid
        },
        payload_key: "inventoryAdjustQuantities"
      )
    end
  end
end
