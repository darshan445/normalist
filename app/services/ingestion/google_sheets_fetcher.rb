# frozen_string_literal: true

require "csv"
require "faraday"
require "json"
require "uri"

module Ingestion
  class GoogleSheetsFetcher
    class Error < StandardError
      attr_reader :code

      def initialize(message, code:)
        super(message)
        @code = code
      end
    end

    class InvalidUrlError < Error
      def initialize(message = "Invalid Google Sheets URL. Use https://docs.google.com/spreadsheets/d/{id}/edit")
        super(message, code: :invalid_url)
      end
    end

    class PrivateSheetError < Error
      def initialize(message = "This Google Sheet is private or not accessible. Publish it to the web or anyone with the link.")
        super(message, code: :private_sheet)
      end
    end

    class FetchError < Error
      def initialize(message = "Could not fetch data from Google Sheets.")
        super(message, code: :fetch_failed)
      end
    end

    class EmptySheetError < Error
      def initialize(message = "This sheet tab contains no data rows.")
        super(message, code: :empty_sheet)
      end
    end

    SHEET_ID_PATTERN = %r{/spreadsheets/d/([a-zA-Z0-9_-]+)}
    TAB_PATTERN = /name:\s*"((?:\\.|[^"\\])*)"\s*,[^}]*gid:\s*"(-?\d+)"/m
    HTML_PREFIXES = %w[<!DOCTYPE <html].freeze
    PRIVATE_MARKERS = [
      "accounts.google.com/ServiceLogin",
      "accounts.google.com/signin",
      "Sign in - Google Accounts"
    ].freeze

    class << self
      def extract_sheet_id(url)
        new(url).sheet_id
      end

      def fetch_tabs(url)
        new(url).fetch_tabs
      end

      def fetch_tab_rows(url:, gid:)
        new(url).fetch_tab_rows(gid: gid)
      end
    end

    def initialize(url)
      @url = url.to_s.strip
      @sheet_id = extract_sheet_id_from_path!
    end

    attr_reader :sheet_id

    def fetch_tabs
      body = get_body(htmlview_url)
      raise PrivateSheetError if private_response?(body)

      tabs = parse_tabs(body)
      raise FetchError, "Could not read sheet tabs from Google Sheets." if tabs.empty?

      tabs
    end

    def fetch_tab_rows(gid:)
      body = get_body(gviz_csv_url(gid))
      validate_csv_access!(body)

      rows = parse_csv_rows(body)
      raise EmptySheetError if rows.empty?

      rows
    end

    private

    def extract_sheet_id_from_path!
      uri = URI.parse(@url)
      match = uri.path.match(SHEET_ID_PATTERN)
      raise InvalidUrlError unless match

      match[1]
    rescue URI::InvalidURIError
      raise InvalidUrlError
    end

    def htmlview_url
      "https://docs.google.com/spreadsheets/d/#{sheet_id}/htmlview"
    end

    def gviz_csv_url(gid)
      "https://docs.google.com/spreadsheets/d/#{sheet_id}/gviz/tq?tqx=out:csv&gid=#{gid}"
    end

    def get_body(url)
      response = connection.get(url)
      raise FetchError, "Google Sheets request failed (HTTP #{response.status})." unless response.success?

      response.body.to_s
    rescue Faraday::Error => e
      raise FetchError, "Google Sheets request failed: #{e.message}"
    end

    def connection
      @connection ||= Faraday.new do |f|
        f.options.timeout = 30
        f.options.open_timeout = 10
        f.headers["User-Agent"] = "NormaList/1.0"
        f.adapter Faraday.default_adapter
      end
    end

    def parse_tabs(body)
      body.scan(TAB_PATTERN).map do |name, gid|
        {
          name: decode_js_string(name),
          gid: gid
        }
      end.uniq { |tab| tab[:gid] }
    end

    def decode_js_string(value)
      JSON.parse(%("#{value.gsub('"', '\\"')}"))
    rescue JSON::ParserError
      value
    end

    def parse_csv_rows(body)
      rows = []
      CSV.parse(body, headers: true, liberal_parsing: true) do |row|
        rows << row.to_h.transform_keys(&:to_s).transform_values { |value| format_cell(value) }
      end

      rows.reject { |row| row.values.all?(&:blank?) }
    end

    def format_cell(value)
      return nil if value.nil?

      value.to_s.strip.presence
    end

    def validate_csv_access!(body)
      return unless html_response?(body)

      raise PrivateSheetError if private_response?(body)

      raise FetchError, "Unexpected response while reading Google Sheets data."
    end

    def html_response?(body)
      stripped = body.to_s.lstrip
      HTML_PREFIXES.any? { |prefix| stripped.start_with?(prefix) }
    end

    def private_response?(body)
      PRIVATE_MARKERS.any? { |marker| body.include?(marker) }
    end
  end
end
