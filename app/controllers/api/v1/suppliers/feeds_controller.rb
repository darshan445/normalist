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

          if feed.file_upload? && params[:file].blank?
            render(json: { errors: ["File is required"] }, status: :unprocessable_entity)
            return
          end

          ActiveRecord::Base.transaction do
            feed.save!
            attach_initial_upload!(feed) if feed.file_upload?
          end

          render(json: detail_payload(feed), status: :created)
        rescue ActiveRecord::RecordInvalid => e
          render(json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity)
        end

        def update
          if @feed.google_sheets? && update_feed_params[:url].blank?
            render(json: { errors: ["Google Sheets URL is required"] }, status: :unprocessable_entity)
            return
          end

          if @feed.update(update_attributes)
            render(json: detail_payload(@feed.reload))
          else
            render(json: { errors: @feed.errors.full_messages }, status: :unprocessable_entity)
          end
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

          { config: @feed.config.merge("url" => update_feed_params[:url].to_s.strip) }
        end

        def feed_params
          params.require(:feed).permit(:feed_type, :url)
        end

        def update_feed_params
          params.require(:feed).permit(:url)
        end

        def feed_config(permitted)
          return {} unless permitted[:feed_type] == "google_sheets"

          { "url" => permitted[:url].to_s.strip }
        end

        def default_feed_name(feed_type)
          case feed_type
          when "file_upload" then "File Upload"
          when "google_sheets" then "Google Sheets"
          else "Feed"
          end
        end
      end
    end
  end
end
