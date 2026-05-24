# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScheduledGoogleSheetsSyncJob, type: :job do
  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant:) }

  it "enqueues sync jobs for due google sheets feeds" do
    due_feed = create(
      :feed,
      merchant:,
      supplier:,
      feed_type: "google_sheets",
      status: "active",
      config: {
        "url" => "https://docs.google.com/spreadsheets/d/abc/edit",
        "tab_gid" => "0",
        "interval" => "daily"
      },
      last_synced_at: 2.days.ago
    )

    create(
      :feed,
      merchant:,
      supplier: create(:supplier, merchant:),
      feed_type: "google_sheets",
      status: "active",
      config: {
        "url" => "https://docs.google.com/spreadsheets/d/def/edit",
        "tab_gid" => "0",
        "interval" => "daily"
      },
      last_synced_at: 1.hour.ago
    )

    expect do
      described_class.perform_now
    end.to have_enqueued_job(GoogleSheetsSyncJob).with(due_feed.id).once
  end
end
