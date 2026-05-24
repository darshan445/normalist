# frozen_string_literal: true

module Schema
  class GoogleSheetsDiscovery
    def self.call(supplier:, url:, gid:)
      new(supplier: supplier, url: url, gid: gid).call
    end

    def initialize(supplier:, url:, gid:)
      @supplier = supplier
      @merchant = supplier.merchant
      @url = url
      @gid = gid
    end

    def call
      rows = Ingestion::GoogleSheetsFetcher.fetch_tab_rows(url: @url, gid: @gid)
      mapping = AiSchemaScanner.call(rows: rows)
      headers = rows.first&.keys || []

      profile = SupplierProfile.find_or_initialize_by(merchant: @merchant, supplier: @supplier)
      profile.apply_schema_discovery!(headers: headers, mapping: mapping)

      {
        profile: profile,
        row_count: rows.size,
        mapping: mapping
      }
    end
  end
end
