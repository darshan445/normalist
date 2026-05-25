# frozen_string_literal: true

require "stringio"

module Ingestion
  # Download blob bytes from remote storage (R2/S3). Prefer over file.open — temp paths
  # from Active Storage can raise FileNotFoundError with cloud backends.
  class UploadFileContent
    def self.call(upload)
      new(upload).call
    end

    def initialize(upload)
      @upload = upload
    end

    def call
      return nil unless @upload.file.attached?

      StringIO.new(@upload.file.blob.download)
    end
  end
end
