# frozen_string_literal: true

class GoogleSheetsSyncJob < ApplicationJob
  queue_as :uploads

  def perform(feed_id)
    feed = Feed.find(feed_id)
    return unless feed.google_sheets? && feed.status == "active"

    feed.with_lock do
      return if feed.sync_in_progress?

      Feeds::GoogleSheetsSync.call(feed: feed)
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("[GoogleSheetsSyncJob] Feed #{feed_id} not found")
  end
end
