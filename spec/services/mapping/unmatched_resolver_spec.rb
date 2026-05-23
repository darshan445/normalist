# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mapping::UnmatchedResolver do
  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant: merchant) }
  let(:upload) { create(:supplier_upload, merchant: merchant, supplier: supplier) }
  let!(:variant) do
    create(:variant,
      merchant: merchant,
      product_title: "Blue Tee",
      variant_title: "Large",
      master_sku: "TEE-BLU-L",
      embedding: Array.new(1536, 0.01))
  end
  let(:unmatched_rows) do
    [
      { "unique_code" => "TSH-BLU-L", "quantity" => 10, "raw_row" => {} },
      { "unique_code" => "TSH-BLU-L", "quantity" => 5, "raw_row" => {} }
    ]
  end

  before do
    allow(Ai::EmbeddingClient).to receive(:embed_batch).and_return([Array.new(1536, 0.01)])
    allow(Shopify::InventoryUpdateJob).to receive(:perform_later)
    allow(Mapping::VariantNeighborSearch).to receive(:call).and_return(
      [
        Mapping::VariantNeighborSearch::Candidate.new(variant: variant, distance: 0.05)
      ]
    )
    allow(Mapping::AiMatchConfirmer).to receive(:call).and_return([])
  end

  it "deduplicates codes and auto-maps high-confidence matches" do
    metrics = Mapping::CodeCountTracker.new
    metrics.mark_unresolved!("TSH-BLU-L")

    result = described_class.call(
      upload: upload,
      unmatched_rows: unmatched_rows,
      code_metrics: metrics
    )

    expect(result.resolved_count).to eq(1)
    expect(result.unresolved_count).to eq(0)
    expect(result.output).to eq([])

    mapping = MappingDictionary.find_by!(merchant: merchant, supplier: supplier, supplier_code: "TSH-BLU-L")
    expect(mapping.status).to eq("mapped")
    expect(mapping.master_sku).to eq("TEE-BLU-L")
    expect(mapping.pending_quantity).to eq(15)
    expect(Shopify::InventoryUpdateJob).to have_received(:perform_later).with(
      merchant.id,
      upload.id,
      mapping.id
    ).once
  end

  it "sends middle-band codes to AI confirmation" do
    allow(Mapping::VariantNeighborSearch).to receive(:call).and_return(
      [
        Mapping::VariantNeighborSearch::Candidate.new(variant: variant, distance: 0.20)
      ]
    )
    allow(Mapping::AiMatchConfirmer).to receive(:call).and_return(
      [
        Mapping::AiMatchConfirmer::Decision.new(
          supplier_code: "TSH-BLU-L",
          variant_id: variant.id,
          confident: true
        )
      ]
    )

    metrics = Mapping::CodeCountTracker.new
    metrics.mark_unresolved!("TSH-BLU-L")

    result = described_class.call(
      upload: upload,
      unmatched_rows: unmatched_rows,
      code_metrics: metrics
    )

    expect(Mapping::AiMatchConfirmer).to have_received(:call)
    expect(result.resolved_count).to eq(1)
  end

  it "creates review mappings when distance is too high" do
    allow(Mapping::VariantNeighborSearch).to receive(:call).and_return(
      [
        Mapping::VariantNeighborSearch::Candidate.new(variant: variant, distance: 0.45)
      ]
    )

    metrics = Mapping::CodeCountTracker.new
    metrics.mark_unresolved!("UNKNOWN")

    result = described_class.call(
      upload: upload,
      unmatched_rows: [ { "unique_code" => "UNKNOWN", "quantity" => 1, "raw_row" => {} } ],
      code_metrics: metrics
    )

    mapping = MappingDictionary.find_by!(merchant: merchant, supplier: supplier, supplier_code: "UNKNOWN")
    expect(mapping.status).to eq("review")
    expect(mapping.supplier_upload_id).to eq(upload.id)
    expect(mapping.platform_variant_id).to eq(variant.platform_variant_id)
    expect(mapping.confidence_score).to eq(0.55)
    expect(mapping.pending_quantity).to eq(1)
    expect(result.output).to eq([ { "unique_code" => "UNKNOWN", "quantity" => 1 } ])
  end
end
