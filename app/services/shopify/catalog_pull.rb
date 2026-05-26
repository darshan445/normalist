# frozen_string_literal: true

module Shopify
  class CatalogPull
    QUERY = <<~GRAPHQL
      query CatalogProducts($cursor: String) {
        products(first: 250, after: $cursor) {
          pageInfo {
            hasNextPage
            endCursor
          }
          edges {
            node {
              title
              variants(first: 250) {
                edges {
                  node {
                    id
                    title
                    sku
                    barcode
                    inventoryItem {
                      id
                    }
                  }
                }
              }
            }
          }
        }
      }
    GRAPHQL

    VariantRow = Data.define(
      :product_title,
      :variant_title,
      :master_sku,
      :barcode,
      :platform_variant_id,
      :platform_inventory_id,
      :needs_sku
    )

    def self.call(session:)
      new(session).call
    end

    def initialize(session)
      @session = session
    end

    def call
      rows = []
      cursor = nil

      loop do
        body = GraphqlClient.call(
          session: @session,
          query: QUERY,
          variables: { cursor: cursor }
        )
        products = body.dig("data", "products")
        break unless products

        products.fetch("edges", []).each do |edge|
          product = edge["node"]
          product.fetch("variants", {}).fetch("edges", []).each do |variant_edge|
            variant = variant_edge["node"]
            variant_id = Gid.numeric_id(variant["id"])
            inventory_item_id = Gid.numeric_id(variant.dig("inventoryItem", "id"))

            rows << VariantRow.new(
              product_title: product["title"],
              variant_title: variant["title"],
              master_sku: variant["sku"].presence || "NO_SKU_#{variant_id}",
              barcode: variant["barcode"].presence,
              platform_variant_id: variant_id,
              platform_inventory_id: inventory_item_id,
              needs_sku: variant["sku"].blank?
            )
          end
        end

        page_info = products["pageInfo"]
        break unless page_info["hasNextPage"]

        cursor = page_info["endCursor"]
      end

      rows
    end
  end
end
