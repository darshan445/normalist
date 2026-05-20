# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mapping::Review::PendingQuantity do
  describe ".aggregate" do
    it "sums integer quantities and ignores blanks" do
      expect(described_class.aggregate([10, 5, "", nil])).to eq(15)
    end

    it "returns nil when no numeric quantities" do
      expect(described_class.aggregate([nil, ""])).to be_nil
    end
  end

  describe ".for_mapping" do
    let(:merchant) { create(:merchant) }
    let(:supplier) { create(:supplier, merchant: merchant) }
    let(:upload) do
      create(
        :supplier_upload,
        merchant: merchant,
        supplier: supplier,
        output: [{ "unique_code" => "SUP-1", "quantity" => 10 }]
      )
    end

    it "prefers pending_quantity on the mapping" do
      mapping = create(
        :mapping_dictionary,
        merchant: merchant,
        supplier: supplier,
        supplier_upload: upload,
        supplier_code: "SUP-1",
        status: "review",
        pending_quantity: 42
      )

      expect(described_class.for_mapping(mapping)).to eq([42])
    end

    it "sets pending_quantity from upload output when blank" do
      mapping = create(
        :mapping_dictionary,
        merchant: merchant,
        supplier: supplier,
        supplier_upload: upload,
        supplier_code: "SUP-1",
        status: "review"
      )

      described_class.ensure_on_mapping!(mapping)

      expect(mapping.reload.pending_quantity).to eq(10)
    end
  end

  describe ".merge_on_mapping!" do
    let(:merchant) { create(:merchant) }
    let(:supplier) { create(:supplier, merchant: merchant) }
    let(:mapping) do
      create(
        :mapping_dictionary,
        merchant: merchant,
        supplier: supplier,
        supplier_code: "SUP-1",
        status: "mapped",
        pending_quantity: 10
      )
    end

    it "aggregates a new row quantity onto the existing pending_quantity" do
      described_class.merge_on_mapping!(mapping, 5)

      expect(mapping.reload.pending_quantity).to eq(15)
    end
  end

  describe ".for_mapping fallback" do
    let(:merchant) { create(:merchant) }
    let(:supplier) { create(:supplier, merchant: merchant) }
    let(:upload) do
      create(
        :supplier_upload,
        merchant: merchant,
        supplier: supplier,
        output: [{ "unique_code" => "SUP-1", "quantity" => 10 }]
      )
    end

    it "falls back to upload output when pending_quantity is blank" do
      mapping = create(
        :mapping_dictionary,
        merchant: merchant,
        supplier: supplier,
        supplier_upload: upload,
        supplier_code: "SUP-1",
        status: "review"
      )

      expect(described_class.for_mapping(mapping)).to eq([10])
    end
  end
end
