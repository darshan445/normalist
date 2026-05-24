# frozen_string_literal: true

module Api
  module V1
    class GoogleSheetsController < BaseController
      def tabs
        tabs = Ingestion::GoogleSheetsFetcher.fetch_tabs(tabs_params[:url])
        render json: { tabs: tabs }
      rescue Ingestion::GoogleSheetsFetcher::Error => e
        render_google_sheets_error(e)
      end

      def preview
        supplier = current_merchant.suppliers.find(preview_params[:supplier_id])

        if preview_params[:tab_gid].blank?
          render json: { errors: ["Sheet tab is required"] }, status: :unprocessable_entity
          return
        end

        rows = Ingestion::GoogleSheetsFetcher.fetch_tab_rows(
          url: preview_params[:url],
          gid: preview_params[:tab_gid]
        )

        mapping = Schema::AiSchemaScanner.call(rows: rows)
        snippet = Schema::RowSnippetBuilder.call(rows: rows)
        preview_columns = preview_columns_for(mapping)

        render json: {
          supplier_id: supplier.id,
          headers: rows.first&.keys || [],
          preview_columns: preview_columns,
          sample_rows: rows.first(10),
          columns: snippet["columns"],
          suggested_sku_column: mapping["supplier_unique_column"],
          suggested_quantity_column: mapping["supplier_quantity_column"],
          suggested_barcode_column: mapping["supplier_barcode_column"],
          suggested_attributes: mapping["supplier_attributes"]
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "not_found", message: "Supplier not found." }, status: :not_found
      rescue Ingestion::GoogleSheetsFetcher::Error => e
        render_google_sheets_error(e)
      rescue ArgumentError => e
        render json: { error: "profile_detection_failed", message: e.message }, status: :unprocessable_entity
      end

      private

      def tabs_params
        params.permit(:url)
      end

      def preview_params
        params.permit(:url, :tab_gid, :supplier_id)
      end

      def preview_columns_for(mapping)
        columns = [
          mapping["supplier_unique_column"],
          mapping["supplier_quantity_column"],
          mapping["supplier_barcode_column"]
        ]

        attributes = mapping["supplier_attributes"]
        columns.concat(attributes.values) if attributes.is_a?(Hash)

        columns.compact.uniq
      end

      def render_google_sheets_error(error)
        status = case error.code
                 when :invalid_url then :unprocessable_entity
                 when :private_sheet then :forbidden
                 when :empty_sheet then :unprocessable_entity
                 else :bad_gateway
                 end

        render json: { error: error.code, message: error.message }, status: status
      end
    end
  end
end
