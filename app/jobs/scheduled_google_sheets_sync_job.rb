# frozen_string_literal: true

class ScheduledGoogleSheetsSyncJob < ApplicationJob
  queue_as :default

  def perform
    due_feeds = Feeds::DueForSync.call

    due_feeds.each do |feed|
      GoogleSheetsSyncJob.perform_later(feed.id)
    end

    Rails.logger.info(
      "[ScheduledGoogleSheetsSyncJob] Enqueued #{due_feeds.size} Google Sheets sync(s)"
    )
  end
end
