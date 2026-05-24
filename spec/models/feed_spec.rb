# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feed do
  describe "#sync_due?" do
    let(:merchant) { create(:merchant) }
    let(:supplier) { create(:supplier, merchant:) }
    let(:feed) do
      create(
        :feed,
        merchant:,
        supplier:,
        feed_type: "google_sheets",
        status: "active",
        config: {
          "url" => "https://docs.google.com/spreadsheets/d/abc/edit",
          "tab_gid" => "0",
          "interval" => interval
        },
        last_synced_at:
      )
    end
    let(:last_synced_at) { nil }
    let(:interval) { "daily" }

    it "is due when never synced" do
      expect(feed.sync_due?).to be(true)
    end

    it "is due when past the daily interval" do
      feed.update!(last_synced_at: 25.hours.ago)
      expect(feed.sync_due?).to be(true)
    end

    it "is not due when inside the daily interval" do
      feed.update!(last_synced_at: 2.hours.ago)
      expect(feed.sync_due?).to be(false)
    end

    context "with every_6_hours interval" do
      let(:interval) { "every_6_hours" }

      it "is due after six hours" do
        feed.update!(last_synced_at: 7.hours.ago)
        expect(feed.sync_due?).to be(true)
      end
    end

    context "when paused" do
      before { feed.update!(status: "paused") }

      it "is not due" do
        expect(feed.sync_due?).to be(false)
      end
    end
  end
end
