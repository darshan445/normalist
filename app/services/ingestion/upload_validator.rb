# frozen_string_literal: true

module Ingestion
  class UploadValidator
    MAX_BYTES = 25 * 1024 * 1024
    MAX_MEGABYTES = MAX_BYTES / 1.megabyte
    SUPPORTED_EXTENSIONS = FileParser::SUPPORTED_EXTENSIONS.freeze

    def self.validate!(uploaded_file)
      new(uploaded_file).validate!
    end

    def initialize(uploaded_file)
      @uploaded_file = uploaded_file
    end

    def validate!
      errors = []
      errors << "File is required" if @uploaded_file.blank?

      if @uploaded_file.present?
        errors << "File is empty" if size.zero?
        errors << "File too large (maximum #{MAX_MEGABYTES} MB)" if size.positive? && size > MAX_BYTES
        errors << unsupported_type_message unless supported_extension?
      end

      raise ArgumentError, errors.join(", ") if errors.any?

      true
    end

    private

    def filename
      @uploaded_file.original_filename.to_s
    end

    def size
      @uploaded_file.size.to_i
    end

    def extension
      File.extname(filename).downcase
    end

    def supported_extension?
      SUPPORTED_EXTENSIONS.include?(extension)
    end

    def unsupported_type_message
      "Unsupported file type. Use CSV or Excel (.xlsx)."
    end
  end
end
