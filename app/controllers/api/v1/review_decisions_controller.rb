# frozen_string_literal: true

module Api
  module V1
    class ReviewDecisionsController < BaseController
      def confirm
        mapping = Mapping::Review::Confirm.call(
          merchant: current_merchant,
          mapping_id: params[:mapping_id]
        )
        render(json: { mapping: serialize_mapping(mapping) })
      rescue Mapping::Review::FindReviewMapping::NotFound
        render_not_found
      rescue Mapping::Review::FindReviewMapping::NotReviewable
        render_not_reviewable
      rescue Mapping::Review::Confirm::VariantNotFound
        render(json: { error: "variant_not_found", message: "Suggested variant not found" }, status: :unprocessable_entity)
      end

      def reject
        mapping = Mapping::Review::Reject.call(
          merchant: current_merchant,
          mapping_id: params[:mapping_id]
        )
        render(json: { mapping: serialize_mapping(mapping) })
      rescue Mapping::Review::FindReviewMapping::NotFound
        render_not_found
      rescue Mapping::Review::FindReviewMapping::NotReviewable
        render_not_reviewable
      end

      def manual_match
        mapping = Mapping::Review::ManualMatch.call(
          merchant: current_merchant,
          mapping_id: params[:mapping_id],
          variant_id: params.require(:variant_id)
        )
        render(json: { mapping: serialize_mapping(mapping) })
      rescue Mapping::Review::FindReviewMapping::NotFound, Mapping::Review::ManualMatch::VariantNotFound
        render_not_found
      rescue Mapping::Review::FindReviewMapping::NotReviewable
        render_not_reviewable
      end

      def bulk_confirm
        result = Mapping::Review::BulkConfirm.call(
          merchant: current_merchant,
          supplier_id: params[:supplier_id],
          suggestion: params.fetch(:suggestion, "suggested")
        )
        render(json: serialize_bulk_result(result))
      end

      def bulk_reject
        result = Mapping::Review::BulkReject.call(
          merchant: current_merchant,
          supplier_id: params[:supplier_id],
          suggestion: params.fetch(:suggestion, "all")
        )
        render(json: serialize_bulk_result(result))
      end

      private

      def serialize_bulk_result(result)
        {
          succeeded: result.succeeded,
          failed: result.failed
        }
      end

      def serialize_mapping(mapping)
        {
          id: mapping.id,
          supplier_code: mapping.supplier_code,
          status: mapping.status,
          master_sku: mapping.master_sku,
          platform_variant_id: mapping.platform_variant_id,
          platform_inventory_id: mapping.platform_inventory_id
        }
      end

      def render_not_found
        render(json: { error: "not_found", message: "Review item not found" }, status: :not_found)
      end

      def render_not_reviewable
        render(
          json: { error: "not_reviewable", message: "Mapping is not awaiting review" },
          status: :unprocessable_entity
        )
      end
    end
  end
end
