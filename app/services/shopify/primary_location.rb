# frozen_string_literal: true

module Shopify
  class PrimaryLocation
    QUERY = <<~GRAPHQL
      query PrimaryLocation {
        locations(first: 1) {
          edges {
            node {
              id
            }
          }
        }
      }
    GRAPHQL

    def self.call(session:)
      new(session).call
    end

    def initialize(session)
      @session = session
    end

    def call
      body = GraphqlClient.call(session: @session, query: QUERY)
      node = body.dig("data", "locations", "edges", 0, "node")
      return if node.blank?

      Gid.numeric_id(node["id"])
    end
  end
end
