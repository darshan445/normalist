# frozen_string_literal: true

module Api
  module V1
    class DashboardController < BaseController
      def show
        render(json: {
          message: "Hello World",
          merchant: {
            id: current_merchant.id,
            name: current_merchant.name,
            platform_domain: current_merchant.platform_domain
          }
        })
      end
    end
  end
end
