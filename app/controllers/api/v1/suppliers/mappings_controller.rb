# frozen_string_literal: true

module Api
  module V1
    module Suppliers
      class MappingsController < BaseController
        def index
          supplier = current_merchant.suppliers.find(params[:supplier_id])
          render(
            json: Api::V1::Suppliers::BuildMappingsIndex.call(
              supplier: supplier,
              page: params[:page],
              per_page: params[:per_page],
              status: params[:status]
            )
          )
        rescue ActiveRecord::RecordNotFound
          render(json: { error: "not_found", message: "Supplier not found" }, status: :not_found)
        end
      end
    end
  end
end
