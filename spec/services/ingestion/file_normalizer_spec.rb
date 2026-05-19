# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ingestion::FileNormalizer do
  let(:csv_path) { Rails.root.join("spec/fixtures/files/normalized_inventory.csv") }

  before do
    FileUtils.mkdir_p(File.dirname(csv_path))
    File.write(csv_path, <<~CSV)
      ,,
      ItemCode_Ref,Avail_Qty,Unit_Price
      XYZ-9982,45,12.00
    CSV
  end

  it "strips leading blank rows and non-printable characters" do
    rows = described_class.call(csv_path.to_s, filename: "sample.csv")

    expect(rows.size).to eq(1)
    expect(rows.first.keys).to eq(%w[ItemCode_Ref Avail_Qty Unit_Price])
    expect(rows.first["ItemCode_Ref"]).to eq("XYZ-9982")
  end
end
