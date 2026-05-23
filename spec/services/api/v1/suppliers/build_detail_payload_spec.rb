# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Suppliers::BuildDetailPayload do
  subject(:payload) { described_class.call(supplier:) }

  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant:) }

  it "returns feeds and mappings for the supplier" do
    feed = create(:feed, merchant:, supplier:, feed_type: "file_upload", name: "File Upload")
    create(
      :supplier_upload,
      merchant:,
      supplier:,
      feed:,
      status: "completed",
      resolved_count: 10,
      unresolved_count: 2
    )
    create(
      :mapping_dictionary,
      merchant:,
      supplier:,
      supplier_code: "ABC-1",
      master_sku: "SKU-1",
      status: "mapped"
    )
    create(
      :mapping_dictionary,
      merchant:,
      supplier:,
      supplier_code: "SKIP-1",
      status: "skipped"
    )
    create(
      :mapping_dictionary,
      merchant:,
      supplier:,
      supplier_code: "PEND-1",
      status: "pending"
    )

    expect(payload[:feeds].first).to include(
      name: "File Upload",
      synced_count: 10,
      pending_count: 2,
      upload_enabled: true
    )
    expect(payload[:mapping_stats]).to eq(
      mapped: 1,
      pending: 1,
      skipped: 1,
      review: 0,
      needs_attention: 1
    )
    expect(payload).not_to have_key(:active_mappings)
    expect(payload).not_to have_key(:pending_mappings)
  end
end
