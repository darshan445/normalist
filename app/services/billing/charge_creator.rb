# frozen_string_literal: true

module Billing
  class ChargeCreator
    def self.call(merchant:, session:)
      new(merchant, session).create
    end

    def initialize(merchant, session)
      @merchant = merchant
      @session = session
    end

    def create
      plan = Plan.active.find_by!(key: "starter")

      charge = ShopifyAPI::RecurringApplicationCharge.new(session: @session)
      charge.name = plan.name
      charge.price = plan.price.to_f
      charge.trial_days = 0
      charge.test = !Rails.env.production?
      charge.return_url = callback_url

      charge.save!

      Rails.logger.info(
        "[ChargeCreator] charge created " \
        "merchant=#{@merchant.id} " \
        "charge_id=#{charge.id}"
      )

      charge.confirmation_url
    rescue ShopifyAPI::Errors::HttpResponseError => e
      message = user_message_for(e)
      Rails.logger.error(
        "[ChargeCreator] charge failed merchant=#{@merchant.id} error=#{e.message}"
      )
      raise ChargeCreationError.new(message, original: e)
    end

    private

    def user_message_for(error)
      body = parse_error_body(error)
      detail = extract_error_detail(body)

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

    def extract_error_detail(body)
      errors = body["errors"]
      return errors if errors.is_a?(String)
      return errors["base"].first if errors.is_a?(Hash) && errors["base"].is_a?(Array)
      return errors["base"] if errors.is_a?(Hash) && errors["base"].present?
      return errors.first if errors.is_a?(Array)

      errors.to_s.presence
    end

    def parse_error_body(error)
      response = error.response
      return {} unless response.respond_to?(:body)

      body = response.body
      return body if body.is_a?(Hash)

      JSON.parse(body.to_s)
    rescue JSON::ParserError
      {}
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
