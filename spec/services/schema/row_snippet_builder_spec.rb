# frozen_string_literal: true

require "rails_helper"

RSpec.describe Schema::RowSnippetBuilder do
  it "builds per-column sample values from informative rows" do
    rows = [
      { "SKU" => nil, "QTY" => nil, "NAME" => nil },
      { "SKU" => "A-1", "QTY" => "10", "NAME" => "Alpha" },
      { "SKU" => "B-2", "QTY" => "3", "NAME" => "Beta" }
    ]

    payload = described_class.call(rows: rows)

    sku_column = payload["columns"].find { |column| column["header"] == "SKU" }
    expect(sku_column["sample_values"]).to eq(["A-1", "B-2"])
  end
end
