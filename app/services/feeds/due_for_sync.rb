# frozen_string_literal: true

module Feeds
  class DueForSync
    def self.call(at: Time.current)
      new(at:).call
    end

    def initialize(at: Time.current)
      @at = at
    end

    def call
      in_progress_feed_ids = SupplierUpload
                             .where(status: %w[pending processing])
                             .where.not(feed_id: nil)
                             .select(:feed_id)

      Feed.active
          .google_sheets
          .where.not(id: in_progress_feed_ids)
          .find_each
          .select { |feed| feed.sync_due?(at: @at) }
    end
  end
end
