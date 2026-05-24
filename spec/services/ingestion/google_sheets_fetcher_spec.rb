# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ingestion::GoogleSheetsFetcher do
  describe ".extract_sheet_id" do
    it "extracts the sheet id from an edit URL path" do
      url = "https://docs.google.com/spreadsheets/d/1gIfWwM6YeFAHgpooRJxq-madNGwf8hzXWHGM0BWb69I/edit"

      expect(described_class.extract_sheet_id(url)).to eq("1gIfWwM6YeFAHgpooRJxq-madNGwf8hzXWHGM0BWb69I")
    end

    it "ignores query strings and hash fragments" do
      url = "https://docs.google.com/spreadsheets/d/abc-123_XYZ/edit?usp=sharing#gid=999"

      expect(described_class.extract_sheet_id(url)).to eq("abc-123_XYZ")
    end

    it "raises for invalid URLs" do
      expect {
        described_class.extract_sheet_id("https://example.com/not-a-sheet")
      }.to raise_error(Ingestion::GoogleSheetsFetcher::InvalidUrlError)
    end
  end
end
