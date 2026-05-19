# frozen_string_literal: true

module Api
  module V1
    class CatalogController < BaseController
      def show
        render(json: Api::V1::Catalog::BuildPayload.call(
          merchant: current_merchant,
          query: params[:q]
        ))
      end
    end
  end
end
