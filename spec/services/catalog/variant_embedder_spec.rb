# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalog::VariantEmbedder do
  let(:merchant) { create(:merchant) }

  before do
    create(:variant,
      merchant: merchant,
      product_title: "Air Runner",
      variant_title: "Black / 9",
      master_sku: "AERO-BLK-09",
      barcode: "1234567890123")

    allow(Ai::EmbeddingClient).to receive(:embed_batch).and_return(
      [Array.new(1536, 0.1)]
    )
  end

  it "embeds all active variants for the merchant" do
    count = described_class.call(merchant: merchant)

    expect(count).to eq(1)
    expect(Ai::EmbeddingClient).to have_received(:embed_batch).with(
      ["Air Runner | Black / 9 | AERO-BLK-09 | 1234567890123"]
    )

    variant = merchant.variants.first
    expect(variant.reload.embedding).to be_present
    expect(variant.embedded_at).to be_present
  end

  it "builds embedding text from variant fields" do
    variant = merchant.variants.first
    expect(variant.embedding_text).to eq("Air Runner | Black / 9 | AERO-BLK-09 | 1234567890123")
  end
end
