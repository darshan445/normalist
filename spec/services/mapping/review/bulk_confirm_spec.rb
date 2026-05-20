# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mapping::Review::BulkConfirm do
  let(:merchant) { create(:merchant) }
  let(:supplier) { create(:supplier, merchant: merchant) }
  let(:variant) do
    create(
      :variant,
      merchant: merchant,
      master_sku: "MASTER-1",
      platform_variant_id: "pv-1"
    )
  end
  let(:upload) { create(:supplier_upload, merchant: merchant, supplier: supplier) }

  before do
    create(
      :mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_upload: upload,
      supplier_code: "SUP-SUG",
      status: "review",
      confidence_score: 0.8,
      master_sku: variant.master_sku,
      platform_variant_id: variant.platform_variant_id
    )
    create(
      :mapping_dictionary,
      merchant: merchant,
      supplier: supplier,
      supplier_code: "SUP-LOW",
      status: "review",
      confidence_score: 0.3
    )
  end

  it "confirms only suggested mappings" do
    result = described_class.call(merchant: merchant, supplier_id: supplier.id, suggestion: "suggested")

    expect(result.succeeded).to eq(1)
    expect(result.failed).to be_empty
    expect(merchant.mapping_dictionaries.find_by(supplier_code: "SUP-SUG").status).to eq("mapped")
    expect(merchant.mapping_dictionaries.find_by(supplier_code: "SUP-LOW").status).to eq("review")
  end
end
