# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Feeds sync", type: :request do
  let(:merchant) do
    create(
      :merchant,
      platform: "shopify",
      platform_domain: "test-store-#{SecureRandom.hex(4)}.myshopify.com",
      access_token: "shpat_test",
      plan_status: "trialing",
      trial_ends_at: 7.days.from_now
    )
  end
  let(:supplier) { create(:supplier, merchant:) }

  before do
    allow(Rails.env).to receive(:development?).and_return(true)
    allow(Rails.env).to receive(:test?).and_return(true)
  end

  describe "POST /api/v1/feeds/:id/sync" do
    it "queues a google sheets sync for the merchant feed" do
      feed = create(
        :feed,
        merchant:,
        supplier:,
        feed_type: "google_sheets",
        config: {
          "url" => "https://docs.google.com/spreadsheets/d/abc/edit",
          "tab_gid" => "0",
          "tab_name" => "Sheet1",
          "interval" => "daily"
        }
      )

      expect do
        post "/api/v1/feeds/#{feed.id}/sync", params: { shop: merchant.platform_domain }
      end.to have_enqueued_job(GoogleSheetsSyncJob).with(feed.id)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "status" => "queued",
        "message" => "Sync started"
      )
    end

    it "rejects sync for file upload feeds" do
      feed = create(:feed, merchant:, supplier:, feed_type: "file_upload")

      post "/api/v1/feeds/#{feed.id}/sync", params: { shop: merchant.platform_domain }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to include("Only Google Sheets feeds can be synced")
    end

    it "returns not found for another merchant feed" do
      other_merchant = create(
        :merchant,
        platform: "shopify",
        platform_domain: "other-#{SecureRandom.hex(4)}.myshopify.com",
        access_token: "shpat_other",
        plan_status: "trialing",
        trial_ends_at: 7.days.from_now
      )
      other_supplier = create(:supplier, merchant: other_merchant)
      feed = create(:feed, merchant: other_merchant, supplier: other_supplier, feed_type: "google_sheets")

      post "/api/v1/feeds/#{feed.id}/sync", params: { shop: merchant.platform_domain }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/feeds/:id/syncs" do
    it "returns the last 10 sync uploads for the feed" do
      feed = create(
        :feed,
        merchant:,
        supplier:,
        feed_type: "google_sheets",
        config: { "url" => "https://example.com", "tab_gid" => "0" }
      )
      upload = create(
        :supplier_upload,
        merchant:,
        supplier:,
        feed:,
        status: "completed",
        resolved_count: 8,
        unresolved_count: 2,
        unique_code_count: 10
      )

      get "/api/v1/feeds/#{feed.id}/syncs", params: { shop: merchant.platform_domain }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["uploads"].length).to eq(1)
      expect(response.parsed_body["uploads"].first).to include(
        "id" => upload.id,
        "status" => "completed",
        "resolved_count" => 8,
        "pending_count" => 2,
        "total_codes" => 10
      )
    end
  end
end
