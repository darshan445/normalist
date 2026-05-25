# frozen_string_literal: true

class GoogleSheetsSyncJob < ApplicationJob
  queue_as :uploads

  def perform(feed_id)
    feed = Feed.find(feed_id)
    return unless feed.google_sheets? && feed.status == "active"

    upload = nil
    feed.with_lock do
      return if feed.sync_in_progress?

      upload = Feeds::GoogleSheetsSync.call(feed: feed)
    end

    SupplierSchemaDiscoveryJob.perform_later(upload.id) if upload
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("[GoogleSheetsSyncJob] Feed #{feed_id} not found")
  end
end
