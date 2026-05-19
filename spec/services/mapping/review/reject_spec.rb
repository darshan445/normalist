# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mapping::Review::Reject do
  let(:merchant) { create(:merchant) }
  let(:other_merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant: merchant) }
  let(:upload) do
    create(
      :supplier_upload,
      merchant: merchant,
      supplier: supplier,
      status: "needs_review",
      unresolved_count: 1,
      resolved_count: 9,
      output: [{ "unique_code" => "SUP-9", "quantity" => 3 }]
    )
  end
  let!(:mapping) do
    create(
      :mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_upload: upload,
      supplier_code: "SUP-9",
      status: "review"
    )
  end

  before do
    allow(Shopify::InventoryUpdateJob).to receive(:perform_later)
  end

  describe "happy path" do
    it "skips the mapping and resolves upload progress without Shopify updates" do
      result = described_class.call(merchant: merchant, mapping_id: mapping.id)

      expect(result.status).to eq("skipped")
      expect(Shopify::InventoryUpdateJob).not_to have_received(:perform_later)

      upload.reload
      expect(upload.unresolved_count).to eq(0)
      expect(upload.status).to eq("completed")
    end
  end

  describe "wrong merchant attempt" do
    it "raises NotFound" do
      expect {
        described_class.call(merchant: other_merchant, mapping_id: mapping.id)
      }.to raise_error(Mapping::Review::FindReviewMapping::NotFound)
    end
  end

  describe "already mapped record attempt" do
    it "raises NotReviewable" do
      mapping.update!(status: "mapped")

      expect {
        described_class.call(merchant: merchant, mapping_id: mapping.id)
      }.to raise_error(Mapping::Review::FindReviewMapping::NotReviewable)
    end
  end
end
