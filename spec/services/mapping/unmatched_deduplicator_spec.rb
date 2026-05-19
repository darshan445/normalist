# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mapping::UnmatchedDeduplicator do
  it "groups quantities by supplier code" do
    rows = [
      { "unique_code" => "A", "quantity" => 10 },
      { "unique_code" => "A", "quantity" => 5 },
      { "unique_code" => "B", "quantity" => 1 }
    ]

    result = described_class.call(rows)

    expect(result.unique_codes).to match_array(%w[A B])
    expect(result.quantities_by_code["A"]).to eq([10, 5])
    expect(result.quantities_by_code["B"]).to eq([1])
  end
end
