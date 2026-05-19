# frozen_string_literal: true

module Api
  module V1
    class ReviewQueueController < BaseController
      def index
        render(json: Api::V1::Review::BuildQueue.call(
          merchant: current_merchant,
          page: params[:page],
          per_page: params[:per_page],
          supplier_id: params[:supplier_id]
        ))
      end
    end
  end
end
