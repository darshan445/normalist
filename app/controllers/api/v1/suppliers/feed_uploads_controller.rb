# frozen_string_literal: true

module Api
  module V1
    module Suppliers
      class FeedUploadsController < BaseController
        before_action :set_supplier
        before_action :set_feed

        def create
          unless @feed.file_upload?
            render(json: { errors: ["Only file upload feeds accept stock files"] }, status: :unprocessable_entity)
            return
          end

          if params[:file].blank?
            render(json: { errors: ["File is required"] }, status: :unprocessable_entity)
            return
          end

          upload = @supplier.supplier_uploads.new(
            merchant: current_merchant,
            supplier: @supplier,
            feed: @feed
          )

          begin
            upload.attach_and_enqueue!(params[:file])
          rescue ActiveRecord::RecordInvalid
            render(json: { errors: upload.errors.full_messages }, status: :unprocessable_entity)
            return
          end

          render(
            json: {
              upload: Api::V1::SupplierUploads::Serialize.call(upload),
              feed: Api::V1::Feeds::Serialize.call(@feed, latest_upload: upload)
            },
            status: :created
          )
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
