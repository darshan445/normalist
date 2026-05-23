# frozen_string_literal: true

module Api
  module V1
    module Suppliers
      module Feeds
        class UploadsController < BaseController
          before_action :set_supplier
          before_action :set_feed

          def index
            render(json: Api::V1::Feeds::BuildUploadHistory.call(feed: @feed))
          end

          private

          def set_supplier
            @supplier = current_merchant.suppliers.find(params[:supplier_id])
          rescue ActiveRecord::RecordNotFound
            render(json: { error: "not_found", message: "Supplier not found" }, status: :not_found)
          end

          def set_feed
            @feed = @supplier.feeds.find(params[:feed_id])
          rescue ActiveRecord::RecordNotFound
            render(json: { error: "not_found", message: "Feed not found" }, status: :not_found)
          end
        end
      end
    end
  end
end
