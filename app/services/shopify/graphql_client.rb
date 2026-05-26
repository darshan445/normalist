# frozen_string_literal: true

module Shopify
  class GraphqlClient
    class Error < StandardError; end

    class UserErrors < Error
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super(errors.map { |entry| entry["message"] }.join("; "))
      end
    end

    def self.call(session:, query:, variables: {})
      new(session).query(query: query, variables: variables)
    end

    def initialize(session)
      @session = session
      @client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
    end

    def query(query:, variables: {})
      response = @client.query(query: query, variables: variables)
      body = response.body

      if body["errors"].present?
        raise Error, body["errors"].map { |entry| entry["message"] }.join("; ")
      end

      body
    end

    def mutate!(query:, variables:, payload_key:)
      body = query(query: query, variables: variables)
      payload = body.dig("data", payload_key)
      user_errors = payload&.fetch("userErrors", []) || []

      if user_errors.any?
        raise UserErrors.new(user_errors)
      end

      payload
    end
  end
end
