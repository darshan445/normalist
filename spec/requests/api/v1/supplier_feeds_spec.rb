# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Suppliers::Feeds", type: :request do
  let(:merchant) do
    create(
      :merchant,
      platform: "shopify",
      platform_domain: "test-store.myshopify.com",
      access_token: "shpat_test"
    )
  end
  let(:supplier) { create(:supplier, merchant:) }

  before do
    allow(Rails.env).to receive(:development?).and_return(true)
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
        config: { "url" => "https://docs.google.com/spreadsheets/d/old" }
      )

      patch "/api/v1/suppliers/#{supplier.id}/feeds/#{feed.id}",
        params: {
          shop: merchant.platform_domain,
          feed: { url: "https://docs.google.com/spreadsheets/d/new" }
        }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["feed"]["url"]).to eq(
        "https://docs.google.com/spreadsheets/d/new"
      )
    end

    it "rejects file upload feed without a file" do
      post "/api/v1/suppliers/#{supplier.id}/feeds",
        params: { shop: merchant.platform_domain, feed: { feed_type: "file_upload" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "creates a google sheets feed with a url" do
      post "/api/v1/suppliers/#{supplier.id}/feeds",
        params: {
          shop: merchant.platform_domain,
          feed: {
            feed_type: "google_sheets",
            url: "https://docs.google.com/spreadsheets/d/abc123"
          }
        }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["feed"]["url"]).to eq(
        "https://docs.google.com/spreadsheets/d/abc123"
      )
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
