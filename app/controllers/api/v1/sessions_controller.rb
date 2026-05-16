# frozen_string_literal: true

module Api
  module V1
    class SessionsController < BaseController
      def show
        render(json: {
          authenticated: true,
          merchant: {
            id: current_merchant.id,
            name: current_merchant.name,
            platform: current_merchant.platform,
            platform_domain: current_merchant.platform_domain
          }
        })
      end
    end
  end
end
