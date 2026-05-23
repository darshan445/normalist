# frozen_string_literal: true

module Api
  module V1
    module Suppliers
      class UploadsController < BaseController
        before_action :set_supplier
        before_action :set_upload

        def show
          render_upload_status
        end

        def status
          render_upload_status
        end

        private

        def set_supplier
          @supplier = current_merchant.suppliers.find(params[:supplier_id])
        rescue ActiveRecord::RecordNotFound
          render(json: { error: "not_found", message: "Supplier not found" }, status: :not_found)
        end

        def set_upload
          @upload = @supplier.supplier_uploads.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render(json: { error: "not_found", message: "Upload not found" }, status: :not_found)
        end

        def render_upload_status
          render(json: { upload: Api::V1::SupplierUploads::Serialize.call(@upload) })
        end
      end
    end
  end
end
