# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ingestion::UploadValidator do
  def uploaded_file(name:, size:, type: "text/csv")
    tempfile = Tempfile.new(name)
    tempfile.write("x" * size) if size.positive?
    tempfile.rewind

    ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: name,
      type: type
    )
  end

  it "accepts a small csv file" do
    file = uploaded_file(name: "stock.csv", size: 100)

    expect { described_class.validate!(file) }.not_to raise_error
  end

  it "rejects unsupported extensions" do
    file = uploaded_file(name: "stock.pdf", size: 100)

    expect { described_class.validate!(file) }.to raise_error(
      ArgumentError,
      /Unsupported file type/
    )
  end

  it "rejects files over the size limit" do
    file = uploaded_file(name: "huge.csv", size: Ingestion::UploadValidator::MAX_BYTES + 1)

    expect { described_class.validate!(file) }.to raise_error(
      ArgumentError,
      /too large/
    )
  end
end
