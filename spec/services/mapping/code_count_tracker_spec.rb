# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mapping::CodeCountTracker do
  it "counts each supplier code once across duplicate rows" do
    tracker = described_class.new

    tracker.mark_unresolved!("SKU-1")
    tracker.mark_unresolved!("SKU-1")
    tracker.mark_resolved!("SKU-1")
    tracker.mark_resolved!("SKU-1")

    expect(tracker.unresolved_count).to eq(0)
    expect(tracker.resolved_count).to eq(1)
    expect(tracker.unique_code_count).to eq(1)
  end
end
