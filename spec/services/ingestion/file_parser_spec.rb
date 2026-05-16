require "rails_helper"

RSpec.describe Ingestion::FileParser do
  let(:csv_path) { Rails.root.join("spec/fixtures/files/sample_inventory.csv") }

  before do
    FileUtils.mkdir_p(File.dirname(csv_path))
    File.write(csv_path, <<~CSV)
      ItemCode_Ref,Avail_Qty,Unit_Price
      XYZ-9982,45,12.00
      XYZ-9983,30,12.00
    CSV
  end

  it "parses CSV from a file path" do
    rows = described_class.call(csv_path.to_s, filename: "sample.csv")

    expect(rows.size).to eq(2)
    expect(rows.first).to eq(
      "ItemCode_Ref" => "XYZ-9982",
      "Avail_Qty" => "45",
      "Unit_Price" => "12.00"
    )
  end

  it "parses CSV from raw string content (ActiveStorage download)" do
    content = File.read(csv_path)
    rows = described_class.call(content, filename: "sample.csv")

    expect(rows.size).to eq(2)
    expect(rows.first["ItemCode_Ref"]).to eq("XYZ-9982")
  end
end
