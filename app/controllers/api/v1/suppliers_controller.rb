# frozen_string_literal: true

module Api
  module V1
    class SuppliersController < BaseController
      def index
        suppliers = current_merchant.suppliers.order(name: :asc)
        pending_counts = mapping_counts_by_supplier("pending")
        mapped_counts = mapping_counts_by_supplier("mapped")

        render(json: {
          suppliers: suppliers.map { |supplier|
            Api::V1::Suppliers::Serialize.call(
              supplier,
              mapped_count: mapped_counts[supplier.id] || 0,
              pending_count: pending_counts[supplier.id] || 0
            )
          }
        })
      end

      def show
        supplier = current_merchant.suppliers.find(params[:id])
        render(json: Api::V1::Suppliers::BuildDetailPayload.call(supplier:))
      rescue ActiveRecord::RecordNotFound
        render(json: { error: "not_found", message: "Supplier not found" }, status: :not_found)
      end

      def create
        supplier = current_merchant.suppliers.new(supplier_params)

        if supplier.save
          render(
            json: { supplier: Api::V1::Suppliers::Serialize.call(supplier) },
            status: :created
          )
        else
          render(json: { errors: supplier.errors.full_messages }, status: :unprocessable_entity)
        end
      end

      private

      def supplier_params
        params.require(:supplier).permit(:name)
      end

      def mapping_counts_by_supplier(status)
        current_merchant.mapping_dictionaries.where(status:).group(:supplier_id).count
      end
    end
  end
end
