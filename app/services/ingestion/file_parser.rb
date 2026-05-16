require "csv"
require "roo"

module Ingestion
  class FileParser
    SUPPORTED_EXTENSIONS = %w[.csv .xlsx].freeze

    def self.call(io_or_path, filename: nil)
      new(io_or_path, filename: filename).call
    end

    def initialize(io_or_path, filename: nil)
      @io_or_path = io_or_path
      @filename = filename
    end

    def call
      path = resolve_path
      extension = File.extname(@filename.presence || path).downcase

      unless SUPPORTED_EXTENSIONS.include?(extension)
        raise ArgumentError, "Unsupported file type. Use CSV or Excel (.xlsx)."
      end

      rows = case extension
             when ".csv" then parse_csv(path)
             when ".xlsx" then parse_xlsx(path)
             end

      raise ArgumentError, "File contains no data rows" if rows.empty?

      rows
    ensure
      @tempfile&.close!
    end

    private

    def resolve_path
      if io_with_readable_path?
        return @io_or_path.path
      end

      @tempfile = Tempfile.new([ "upload", extension_suffix ])
      @tempfile.binmode
      content = extract_content
      raise ArgumentError, "No file content provided" if content.nil?

      @tempfile.write(content)
      @tempfile.rewind
      @tempfile.path
    end

    def io_with_readable_path?
      @io_or_path.respond_to?(:path) &&
        @io_or_path.path.present? &&
        File.file?(@io_or_path.path)
    end

    def extract_content
      case @io_or_path
      when nil
        nil
      when String
        # ActiveStorage#download returns raw bytes; only treat as a path if it exists on disk.
        if File.file?(@io_or_path)
          File.binread(@io_or_path)
        else
          @io_or_path
        end
      else
        if @io_or_path.respond_to?(:download)
          @io_or_path.download
        elsif @io_or_path.respond_to?(:read)
          @io_or_path.rewind if @io_or_path.respond_to?(:rewind)
          @io_or_path.read
        else
          raise ArgumentError, "Unsupported file input: #{@io_or_path.class.name}"
        end
      end
    end

    def extension_suffix
      ext = File.extname(@filename.to_s)
      ext.present? ? ext : ".csv"
    end

    def parse_csv(path)
      rows = []
      CSV.foreach(path, headers: true, encoding: "bom|utf-8") do |row|
        rows << row.to_h.transform_keys(&:to_s)
      end
      rows
    end

    def parse_xlsx(path)
      sheet = Roo::Spreadsheet.open(path).sheet(0)
      headers = sheet.row(1).map { |h| h.to_s.strip }
      (2..sheet.last_row).map do |i|
        values = sheet.row(i)
        headers.each_with_index.with_object({}) do |(header, idx), hash|
          hash[header] = values[idx].nil? ? nil : values[idx].to_s
        end
      end
    end
  end
end
