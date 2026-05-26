# frozen_string_literal: true

module Billing
  class ChargeCreator
    CREATE_MUTATION = <<~GRAPHQL
      mutation AppSubscriptionCreate(
        $name: String!,
        $lineItems: [AppSubscriptionLineItemInput!]!,
        $returnUrl: URL!,
        $test: Boolean,
        $trialDays: Int
      ) {
        appSubscriptionCreate(
          name: $name,
          returnUrl: $returnUrl,
          lineItems: $lineItems,
          test: $test,
          trialDays: $trialDays
        ) {
          userErrors {
            field
            message
          }
          appSubscription {
            id
          }
          confirmationUrl
        }
      }
    GRAPHQL

    def self.call(merchant:, session:)
      new(merchant, session).create
    end

    def initialize(merchant, session)
      @merchant = merchant
      @session = session
    end

    def create
      plan = Plan.active.find_by!(key: "starter")
      client = Shopify::GraphqlClient.new(@session)

      payload = client.mutate!(
        query: CREATE_MUTATION,
        variables: {
          name: plan.name,
          returnUrl: callback_url,
          test: !Rails.env.production?,
          trialDays: 0,
          lineItems: [
            {
              plan: {
                appRecurringPricingDetails: {
                  price: {
                    amount: plan.price.to_f,
                    currencyCode: "USD"
                  },
                  interval: "EVERY_30_DAYS"
                }
              }
            }
          ]
        },
        payload_key: "appSubscriptionCreate"
      )

      confirmation_url = payload["confirmationUrl"]
      subscription_id = Shopify::Gid.numeric_id(payload.dig("appSubscription", "id"))

      Rails.logger.info(
        "[ChargeCreator] subscription created " \
        "merchant=#{@merchant.id} " \
        "subscription_id=#{subscription_id}"
      )

      confirmation_url
    rescue Shopify::GraphqlClient::UserErrors => e
      message = user_message_for(e.message)
      Rails.logger.error(
        "[ChargeCreator] charge failed merchant=#{@merchant.id} error=#{e.message}"
      )
      raise ChargeCreationError.new(message, original: e)
    rescue Shopify::GraphqlClient::Error => e
      message = user_message_for(e.message)
      Rails.logger.error(
        "[ChargeCreator] charge failed merchant=#{@merchant.id} error=#{e.message}"
      )
      raise ChargeCreationError.new(message, original: e)
    rescue ShopifyAPI::Errors::HttpResponseError => e
      message = user_message_for(e.message)
      Rails.logger.error(
        "[ChargeCreator] charge failed merchant=#{@merchant.id} error=#{e.message}"
      )
      raise ChargeCreationError.new(message, original: e)
    end

    private

    def user_message_for(detail)
      if detail.to_s.match?(/invalid api key|access token|unrecognized login/i)
        "Shopify session expired. Reopen NormaList from Shopify Admin and try again."
      elsif detail.to_s.include?("Shopify partners")
        "Billing is not set up for this app yet. Create the app in the " \
        "Shopify Partners dashboard and install it on your development store " \
        "from there (not as a custom app owned by the shop)."
      elsif detail.present?
        detail
      else
        "Could not create subscription charge. Please try again or contact support."
      end
    end

    def callback_url
      shop = CGI.escape(@merchant.platform_domain.to_s)
      "#{app_base_url}/billing/callback?shop=#{shop}"
    end

    def app_base_url
      raw = ENV.fetch("HOST").to_s.strip.delete_suffix("/")
      raw.start_with?("http") ? raw : "https://#{raw}"
    end
  end
end
