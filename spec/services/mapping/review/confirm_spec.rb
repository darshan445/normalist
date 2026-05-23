# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mapping::Review::Confirm do
  let(:merchant) { create(:merchant) }
  let(:other_merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant: merchant) }
  let(:variant) do
    create(
      :variant,
      merchant: merchant,
      master_sku: "MASTER-1",
      platform_variant_id: "pv-1",
      platform_inventory_id: "pi-1"
    )
  end
  let(:upload) do
    create(
      :supplier_upload,
      merchant: merchant,
      supplier: supplier,
      status: "needs_review",
      unresolved_count: 1,
      resolved_count: 8,
      unique_code_count: 9,
      output: [
        { "unique_code" => "SUP-1", "quantity" => 10 },
        { "unique_code" => "SUP-1", "quantity" => 5 }
      ]
    )
  end
  let!(:mapping) do
    create(
      :mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_upload: upload,
      supplier_code: "SUP-1",
      status: "review",
      master_sku: variant.master_sku,
      platform_variant_id: variant.platform_variant_id,
      platform_inventory_id: variant.platform_inventory_id,
      confidence_score: 0.82
    )
  end

  before do
    allow(Shopify::InventoryUpdateJob).to receive(:perform_later)
  end

  describe "happy path" do
    it "maps the review item, enqueues Shopify updates, and updates upload progress" do
      result = described_class.call(merchant: merchant, mapping_id: mapping.id)

      expect(result.status).to eq("mapped")
      expect(result.master_sku).to eq("MASTER-1")
      expect(mapping.reload.pending_quantity).to eq(15)
      expect(Shopify::InventoryUpdateJob).to have_received(:perform_later).with(
        merchant.id,
        upload.id,
        mapping.id
      ).once

      upload.reload
      expect(upload.resolved_count).to eq(9)
      expect(upload.unresolved_count).to eq(0)
      expect(upload.output).to eq([])
      expect(upload.status).to eq("completed")
      expect(upload.stage).to eq("complete")
    end

    it "uses pending_quantity when set instead of per-row upload quantities" do
      mapping.update!(pending_quantity: 15)

      described_class.call(merchant: merchant, mapping_id: mapping.id)

      expect(Shopify::InventoryUpdateJob).to have_received(:perform_later).with(
        merchant.id,
        upload.id,
        mapping.id
      ).once
      expect(mapping.reload.pending_quantity).to eq(15)
    end
  end

  describe "wrong merchant attempt" do
    it "raises NotFound when the mapping belongs to another merchant" do
      expect {
        described_class.call(merchant: other_merchant, mapping_id: mapping.id)
      }.to raise_error(Mapping::Review::FindReviewMapping::NotFound)
    end
  end

  describe "already mapped record attempt" do
    it "raises NotReviewable when the mapping is no longer in review" do
      mapping.update!(status: "mapped")

      expect {
        described_class.call(merchant: merchant, mapping_id: mapping.id)
      }.to raise_error(Mapping::Review::FindReviewMapping::NotReviewable)
    end
  end
end
