# frozen_string_literal: true

module Api
  module V1
    class DashboardController < BaseController
      def show
        render(json: Api::V1::Dashboard::BuildPayload.call(merchant: current_merchant))
      end
    end
  end
end
