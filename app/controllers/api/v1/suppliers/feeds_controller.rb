# frozen_string_literal: true

module Api
  module V1
    module Suppliers
      class FeedsController < BaseController
        before_action :set_supplier
        before_action :set_feed, only: %i[show update]

        def show
          render(json: detail_payload(@feed))
        end

        def create
          feed = @supplier.feeds.new(create_attributes)

          if feed.google_sheets? && feed.config["url"].blank?
            render(json: { errors: ["Google Sheets URL is required"] }, status: :unprocessable_entity)
            return
          end

          if feed.google_sheets? && feed.config["tab_gid"].blank?
            render(json: { errors: ["Sheet tab is required"] }, status: :unprocessable_entity)
            return
          end

          if feed.file_upload? && params[:file].blank?
            render(json: { errors: ["File is required"] }, status: :unprocessable_entity)
            return
          end

          ActiveRecord::Base.transaction do
            feed.save!
            attach_initial_upload!(feed) if feed.file_upload?
            discover_google_sheets!(feed) if feed.google_sheets?
          end

          render(json: detail_payload(feed.reload), status: :created)
        rescue ActiveRecord::RecordInvalid => e
          render(json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity)
        rescue Ingestion::GoogleSheetsFetcher::Error => e
          render_google_sheets_error(e)
        rescue ArgumentError => e
          render(json: { error: "profile_detection_failed", message: e.message }, status: :unprocessable_entity)
        end

        def update
          if @feed.google_sheets? && update_feed_params[:url].blank?
            render(json: { errors: ["Google Sheets URL is required"] }, status: :unprocessable_entity)
            return
          end

          if @feed.google_sheets? && update_feed_params[:tab_gid].blank?
            render(json: { errors: ["Sheet tab is required"] }, status: :unprocessable_entity)
            return
          end

          config_changed = google_sheets_config_changed?

          ActiveRecord::Base.transaction do
            @feed.update!(update_attributes)
            discover_google_sheets!(@feed) if @feed.google_sheets? && config_changed
          end

          render(json: detail_payload(@feed.reload))
        rescue ActiveRecord::RecordInvalid => e
          render(json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity)
        rescue Ingestion::GoogleSheetsFetcher::Error => e
          render_google_sheets_error(e)
        rescue ArgumentError => e
          render(json: { error: "profile_detection_failed", message: e.message }, status: :unprocessable_entity)
        end

        private

        def set_supplier
          @supplier = current_merchant.suppliers.find(params[:supplier_id])
        rescue ActiveRecord::RecordNotFound
          render(json: { error: "not_found", message: "Supplier not found" }, status: :not_found)
        end

        def set_feed
          @feed = @supplier.feeds.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render(json: { error: "not_found", message: "Feed not found" }, status: :not_found)
        end

        def detail_payload(feed)
          {
            supplier: {
              id: @supplier.id,
              name: @supplier.name
            },
            supplier_profile: Api::V1::SupplierProfiles::Serialize.call(@supplier.supplier_profile),
            feed: Api::V1::Feeds::Serialize.call(feed, latest_upload: latest_upload_for(feed))
          }
        end

        def latest_upload_for(feed)
          feed.supplier_uploads.order(created_at: :desc).first
        end

        def attach_initial_upload!(feed)
          upload = @supplier.supplier_uploads.new(
            merchant: current_merchant,
            supplier: @supplier,
            feed: feed
          )
          upload.attach_and_enqueue!(params[:file])
        end

        def discover_google_sheets!(feed)
          Schema::GoogleSheetsDiscovery.call(
            supplier: @supplier,
            url: feed.config["url"],
            gid: feed.config["tab_gid"]
          )
        end

        def google_sheets_config_changed?
          return false unless @feed.google_sheets?

          permitted = update_feed_params
          @feed.config["url"] != permitted[:url].to_s.strip ||
            @feed.config["tab_gid"] != permitted[:tab_gid].to_s
        end

        def create_attributes
          permitted = feed_params
          {
            merchant: current_merchant,
            name: default_feed_name(permitted[:feed_type]),
            feed_type: permitted[:feed_type],
            status: "active",
            config: feed_config(permitted)
          }
        end

        def update_attributes
          return {} unless @feed.google_sheets?

          permitted = update_feed_params
          {
            config: @feed.config.merge(
              "url" => permitted[:url].to_s.strip,
              "tab_gid" => permitted[:tab_gid].to_s,
              "tab_name" => permitted[:tab_name].to_s,
              "interval" => sync_interval_value(permitted[:interval])
            )
          }
        end

        def feed_params
          params.require(:feed).permit(:feed_type, :url, :tab_gid, :tab_name, :interval)
        end

        def update_feed_params
          params.require(:feed).permit(:url, :tab_gid, :tab_name, :interval)
        end

        def feed_config(permitted)
          return {} unless permitted[:feed_type] == "google_sheets"

          {
            "url" => permitted[:url].to_s.strip,
            "tab_gid" => permitted[:tab_gid].to_s,
            "tab_name" => permitted[:tab_name].to_s,
            "interval" => sync_interval_value(permitted[:interval])
          }
        end

        def sync_interval_value(value)
          interval = value.presence || Feed::DEFAULT_SYNC_INTERVAL
          Feed::SYNC_INTERVALS.include?(interval) ? interval : Feed::DEFAULT_SYNC_INTERVAL
        end

        def default_feed_name(feed_type)
          case feed_type
          when "file_upload" then "File Upload"
          when "google_sheets" then "Google Sheets"
          else "Feed"
          end
        end

        def render_google_sheets_error(error)
          status = case error.code
                   when :invalid_url then :unprocessable_entity
                   when :private_sheet then :forbidden
                   when :empty_sheet then :unprocessable_entity
                   else :bad_gateway
                   end

          render(json: { error: error.code, message: error.message }, status: status)
        end
      end
    end
  end
end
