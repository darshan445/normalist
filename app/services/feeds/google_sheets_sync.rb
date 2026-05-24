# frozen_string_literal: true

require "csv"
require "stringio"

module Feeds
  class GoogleSheetsSync
    def self.call(feed:)
      new(feed:).call
    end

    def initialize(feed:)
      @feed = feed
    end

    def call
      rows = Ingestion::GoogleSheetsFetcher.fetch_tab_rows(
        url: @feed.config["url"],
        gid: @feed.config["tab_gid"]
      )

      upload = @feed.supplier.supplier_uploads.create!(
        merchant: @feed.merchant,
        supplier: @feed.supplier,
        feed: @feed,
        status: "pending"
      )

      upload.file.attach(
        io: StringIO.new(rows_to_csv(rows)),
        filename: "google-sheet-sync.csv",
        content_type: "text/csv"
      )

      SupplierSchemaDiscoveryJob.perform_later(upload.id)
      upload
    end

    private

    def rows_to_csv(rows)
      return "" if rows.empty?

      headers = rows.first.keys
      CSV.generate do |csv|
        csv << headers
        rows.each { |row| csv << headers.map { |header| row[header] } }
      end
    end
  end
end
