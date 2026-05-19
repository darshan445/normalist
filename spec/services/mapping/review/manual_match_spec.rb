# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mapping::Review::ManualMatch do
  let(:merchant) { create(:merchant) }
  let(:other_merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant: merchant) }
  let(:chosen_variant) do
    create(
      :variant,
      merchant: merchant,
      master_sku: "PICK-1",
      platform_variant_id: "pv-pick",
      platform_inventory_id: "pi-pick"
    )
  end
  let(:upload) do
    create(
      :supplier_upload,
      merchant: merchant,
      supplier: supplier,
      status: "needs_review",
      unresolved_count: 1,
      resolved_count: 4,
      output: [{ "unique_code" => "UNKNOWN-1", "quantity" => 7 }]
    )
  end
  let!(:mapping) do
    create(
      :mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_upload: upload,
      supplier_code: "UNKNOWN-1",
      status: "review"
    )
  end

  before do
    allow(Shopify::InventoryUpdateJob).to receive(:perform_later)
  end

  describe "happy path" do
    it "maps to the selected variant and enqueues Shopify updates" do
      result = described_class.call(
        merchant: merchant,
        mapping_id: mapping.id,
        variant_id: chosen_variant.id
      )

      expect(result.status).to eq("mapped")
      expect(result.master_sku).to eq("PICK-1")
      expect(result.platform_variant_id).to eq("pv-pick")
      expect(Shopify::InventoryUpdateJob).to have_received(:perform_later).with(
        merchant.id,
        upload.id,
        mapping.id,
        7
      )

      upload.reload
      expect(upload.unresolved_count).to eq(0)
      expect(upload.status).to eq("completed")
    end
  end

  describe "wrong merchant attempt" do
    it "raises NotFound for a mapping owned by another merchant" do
      expect {
        described_class.call(
          merchant: other_merchant,
          mapping_id: mapping.id,
          variant_id: chosen_variant.id
        )
      }.to raise_error(Mapping::Review::FindReviewMapping::NotFound)
    end

    it "raises VariantNotFound when the variant belongs to another merchant" do
      other_variant = create(:variant, merchant: other_merchant)

      expect {
        described_class.call(
          merchant: merchant,
          mapping_id: mapping.id,
          variant_id: other_variant.id
        )
      }.to raise_error(Mapping::Review::ManualMatch::VariantNotFound)
    end
  end

  describe "already mapped record attempt" do
    it "raises NotReviewable" do
      mapping.update!(status: "mapped")

      expect {
        described_class.call(
          merchant: merchant,
          mapping_id: mapping.id,
          variant_id: chosen_variant.id
        )
      }.to raise_error(Mapping::Review::FindReviewMapping::NotReviewable)
    end
  end
end
