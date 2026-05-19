# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalog::ShopifyProductSync do
  let(:merchant) { create(:merchant) }
  let(:product) do
    {
      "title" => "Short sleeves T-shirt",
      "variants" => [
        {
          "id" => 45_850_784_825_480,
          "title" => "Red",
          "sku" => "TSHIRT-RED-S",
          "barcode" => "",
          "inventory_item_id" => 47_957_016_674_440
        }
      ]
    }
  end

  it "creates a variant with the same fields as catalog sync and enqueues embedding" do
    expect {
      described_class.call(merchant: merchant, product: product)
    }.to have_enqueued_job(Catalog::VariantEmbeddingJob)
      .with(merchant.id, variant_ids: [kind_of(String)])

    variant = merchant.variants.find_by!(platform_variant_id: "45850784825480")
    expect(variant).to have_attributes(
      product_title: "Short sleeves T-shirt",
      variant_title: "Red",
      master_sku: "TSHIRT-RED-S",
      platform: "shopify",
      platform_inventory_id: "47957016674440",
      status: "active",
      needs_sku: false
    )
  end

  it "updates an existing variant matched by platform_variant_id" do
    existing = create(
      :variant,
      merchant: merchant,
      platform_variant_id: "45850784825480",
      master_sku: "TSHIRT-RED-S",
      product_title: "Old title",
      embedding: Array.new(1536, 0.1),
      embedded_at: 1.day.ago
    )

    expect {
      described_class.call(merchant: merchant, product: product)
    }.to have_enqueued_job(Catalog::VariantEmbeddingJob)
      .with(merchant.id, variant_ids: [existing.id])

    expect(existing.reload.product_title).to eq("Short sleeves T-shirt")
  end

  it "does not enqueue embedding when searchable fields are unchanged" do
    existing = create(
      :variant,
      merchant: merchant,
      platform_variant_id: "45850784825480",
      product_title: "Short sleeves T-shirt",
      variant_title: "Red",
      master_sku: "TSHIRT-RED-S",
      embedding: Array.new(1536, 0.1),
      embedded_at: 1.day.ago
    )

    expect {
      described_class.call(merchant: merchant, product: product)
    }.not_to have_enqueued_job(Catalog::VariantEmbeddingJob)

    expect(existing.reload.synced_at).to be_present
  end
end
