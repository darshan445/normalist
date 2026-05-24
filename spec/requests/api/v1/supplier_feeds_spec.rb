# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Suppliers::Feeds", type: :request do
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

  describe "POST /api/v1/suppliers/:supplier_id/feeds" do
    it "creates a file upload feed with a file" do
      file = fixture_file_upload("sample_stock.csv", "text/csv")

      post "/api/v1/suppliers/#{supplier.id}/feeds",
        params: {
          shop: merchant.platform_domain,
          feed: { feed_type: "file_upload" },
          file: file
        }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["feed"]).to include(
        "feed_type" => "file_upload",
        "name" => "File Upload",
        "upload_enabled" => true
      )
      expect(response.parsed_body["supplier"]["id"]).to eq(supplier.id)
    end

    it "shows a feed" do
      feed = create(:feed, merchant:, supplier:, name: "My Feed")

      get "/api/v1/suppliers/#{supplier.id}/feeds/#{feed.id}",
        params: { shop: merchant.platform_domain }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["feed"]["id"]).to eq(feed.id)
    end

    it "updates a google sheets feed url" do
      feed = create(
        :feed,
        merchant:,
        supplier:,
        feed_type: "google_sheets",
        config: {
          "url" => "https://docs.google.com/spreadsheets/d/old/edit",
          "tab_gid" => "111",
          "tab_name" => "Old tab"
        }
      )

      allow(Schema::GoogleSheetsDiscovery).to receive(:call)

      patch "/api/v1/suppliers/#{supplier.id}/feeds/#{feed.id}",
        params: {
          shop: merchant.platform_domain,
          feed: {
            url: "https://docs.google.com/spreadsheets/d/new/edit",
            tab_gid: "222",
            tab_name: "New tab"
          }
        }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["feed"]).to include(
        "url" => "https://docs.google.com/spreadsheets/d/new/edit",
        "tab_gid" => "222",
        "tab_name" => "New tab"
      )
      expect(Schema::GoogleSheetsDiscovery).to have_received(:call).once
    end

    it "rejects file upload feed without a file" do
      post "/api/v1/suppliers/#{supplier.id}/feeds",
        params: { shop: merchant.platform_domain, feed: { feed_type: "file_upload" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "creates a google sheets feed with a url and tab" do
      allow(Schema::GoogleSheetsDiscovery).to receive(:call)

      post "/api/v1/suppliers/#{supplier.id}/feeds",
        params: {
          shop: merchant.platform_domain,
          feed: {
            feed_type: "google_sheets",
            url: "https://docs.google.com/spreadsheets/d/abc123/edit",
            tab_gid: "1005365070",
            tab_name: "Stock"
          }
        }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["feed"]).to include(
        "url" => "https://docs.google.com/spreadsheets/d/abc123/edit",
        "tab_gid" => "1005365070",
        "tab_name" => "Stock"
      )
      expect(Schema::GoogleSheetsDiscovery).to have_received(:call).once
    end

    it "rejects google sheets without a tab" do
      post "/api/v1/suppliers/#{supplier.id}/feeds",
        params: {
          shop: merchant.platform_domain,
          feed: {
            feed_type: "google_sheets",
            url: "https://docs.google.com/spreadsheets/d/abc123/edit"
          }
        }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects duplicate feed type for the same supplier" do
      create(:feed, merchant:, supplier:, feed_type: "file_upload")

      file = fixture_file_upload("sample_stock.csv", "text/csv")
      post "/api/v1/suppliers/#{supplier.id}/feeds",
        params: {
          shop: merchant.platform_domain,
          feed: { feed_type: "file_upload" },
          file: file
        }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"].join).to match(/already exists/i)
    end

    it "rejects google sheets without a url" do
      post "/api/v1/suppliers/#{supplier.id}/feeds",
        params: {
          shop: merchant.platform_domain,
          feed: { feed_type: "google_sheets" }
        }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
