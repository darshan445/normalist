# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::DueForSync do
  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant:) }

  def google_sheets_feed(**attrs)
    create(
      :feed,
      merchant:,
      supplier:,
      feed_type: "google_sheets",
      config: {
        "url" => "https://docs.google.com/spreadsheets/d/abc/edit",
        "tab_gid" => "0",
        "interval" => "daily"
      },
      **attrs
    )
  end

  it "returns active google sheets feeds that are due and not syncing" do
    due_feed = google_sheets_feed(last_synced_at: 2.days.ago)
    recent_feed = google_sheets_feed(
      supplier: create(:supplier, merchant:),
      config: {
        "url" => "https://docs.google.com/spreadsheets/d/recent/edit",
        "tab_gid" => "0",
        "interval" => "daily"
      },
      last_synced_at: 1.hour.ago
    )
    never_synced = google_sheets_feed(
      supplier: create(:supplier, merchant:),
      config: {
        "url" => "https://docs.google.com/spreadsheets/d/new/edit",
        "tab_gid" => "0",
        "interval" => "daily"
      },
      last_synced_at: nil
    )
    paused_feed = google_sheets_feed(
      supplier: create(:supplier, merchant:),
      status: "paused",
      config: {
        "url" => "https://docs.google.com/spreadsheets/d/paused/edit",
        "tab_gid" => "0",
        "interval" => "daily"
      },
      last_synced_at: 2.days.ago
    )
    file_feed = create(
      :feed,
      merchant:,
      supplier: create(:supplier, merchant:),
      feed_type: "file_upload",
      last_synced_at: 2.days.ago
    )
    syncing_feed = google_sheets_feed(
      supplier: create(:supplier, merchant:),
      config: {
        "url" => "https://docs.google.com/spreadsheets/d/syncing/edit",
        "tab_gid" => "0",
        "interval" => "daily"
      },
      last_synced_at: 2.days.ago
    )
    create(:supplier_upload, merchant:, supplier: syncing_feed.supplier, feed: syncing_feed, status: "processing")

    result = described_class.call(at: Time.current)

    expect(result).to contain_exactly(due_feed, never_synced)
    expect(result).not_to include(recent_feed, paused_feed, file_feed, syncing_feed)
  end

  it "respects the feed sync interval" do
    six_hour_feed = google_sheets_feed(
      supplier: create(:supplier, merchant:),
      config: {
        "url" => "https://docs.google.com/spreadsheets/d/abc/edit",
        "tab_gid" => "0",
        "interval" => "every_6_hours"
      },
      last_synced_at: 7.hours.ago
    )
    recent_six_hour_feed = google_sheets_feed(
      supplier: create(:supplier, merchant:),
      config: {
        "url" => "https://docs.google.com/spreadsheets/d/def/edit",
        "tab_gid" => "0",
        "interval" => "every_6_hours"
      },
      last_synced_at: 5.hours.ago
    )

    result = described_class.call(at: Time.current)

    expect(result).to include(six_hour_feed)
    expect(result).not_to include(recent_six_hour_feed)
  end
end
