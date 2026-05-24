# frozen_string_literal: true

module Api
  module V1
    class FeedsController < BaseController
      before_action :set_feed

      def sync
        unless @feed.google_sheets?
          render(json: { errors: ["Only Google Sheets feeds can be synced"] }, status: :unprocessable_entity)
          return
        end

        GoogleSheetsSyncJob.perform_later(@feed.id)

        render(json: { status: "queued", message: "Sync started" })
      end

      def syncs
        render(json: Api::V1::Feeds::BuildUploadHistory.call(feed: @feed))
      end

      private

      def set_feed
        @feed = Feed.for_merchant(current_merchant.id).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render(json: { error: "not_found", message: "Feed not found" }, status: :not_found)
      end
    end
  end
end
