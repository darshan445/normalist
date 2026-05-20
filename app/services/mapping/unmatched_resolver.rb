# frozen_string_literal: true

module Mapping
  class UnmatchedResolver
    HIGH_CONFIDENCE_DISTANCE = 0.10
    AI_BAND_MAX_DISTANCE = 0.30

    Result = Data.define(
      :resolved_count,
      :unresolved_count,
      :output,
      :stage_message
    )

    def self.call(upload:, unmatched_rows:, initial_resolved_count:, initial_unresolved_count:)
      new(
        upload: upload,
        unmatched_rows: unmatched_rows,
        initial_resolved_count: initial_resolved_count,
        initial_unresolved_count: initial_unresolved_count
      ).call
    end

    def initialize(upload:, unmatched_rows:, initial_resolved_count:, initial_unresolved_count:)
      @upload = upload
      @merchant = upload.merchant
      @supplier = upload.supplier
      @unmatched_rows = unmatched_rows
      @resolved_count = initial_resolved_count
      @unresolved_count = initial_unresolved_count
      @review_output = []
    end

    def call
      deduped = UnmatchedDeduplicator.call(@unmatched_rows)
      return finished("No unmatched codes to resolve") if deduped.unique_codes.empty?

      code_vectors = embed_supplier_codes(deduped.unique_codes)
      ai_band_entries = []

      deduped.unique_codes.each_with_index do |supplier_code, index|
        quantities = deduped.quantities_by_code[supplier_code]
        neighbors = VariantNeighborSearch.call(merchant: @merchant, vector: code_vectors[index])
        top = neighbors.first

        if top.nil? || top.distance > AI_BAND_MAX_DISTANCE
          apply_review!(
            supplier_code: supplier_code,
            variant: top&.variant,
            quantities: quantities,
            confidence_score: confidence_from(top)
          )
        elsif top.distance < HIGH_CONFIDENCE_DISTANCE
          apply_mapped!(supplier_code: supplier_code, master_sku: top.variant.master_sku, quantities: quantities)
        else
          ai_band_entries << { supplier_code: supplier_code, quantities: quantities, candidates: neighbors }
        end
      end

      resolve_ai_band!(ai_band_entries)

      finished(phase_three_message(deduped.unique_codes.size))
    end

    private

    def embed_supplier_codes(codes)
      Ai::EmbeddingClient.embed_batch(codes)
    end

    def resolve_ai_band!(entries)
      return if entries.empty?

      decisions = AiMatchConfirmer.call(entries: entries)
      decisions_by_code = decisions.index_by(&:supplier_code)

      entries.each do |entry|
        decision = decisions_by_code[entry[:supplier_code]]
        quantities = entry[:quantities]

        if decision&.confident && decision.variant_id.present?
          variant = @merchant.variants.active.find_by(id: decision.variant_id)
          if variant
            apply_mapped!(supplier_code: entry[:supplier_code], master_sku: variant.master_sku, quantities: quantities)
            next
          end
        end

        top = entry[:candidates].first
        apply_review!(
          supplier_code: entry[:supplier_code],
          variant: top&.variant,
          quantities: quantities,
          confidence_score: confidence_from(top)
        )
      end
    end

    def apply_mapped!(supplier_code:, master_sku:, quantities:)
      variant = @merchant.variants.active.find_by!(master_sku: master_sku)
      mapping = persist_mapping!(
        supplier_code: supplier_code,
        variant: variant,
        status: "mapped",
        quantities: quantities
      )

      row_count = quantities.size
      @resolved_count += row_count
      @unresolved_count -= row_count

      ShopifyInventoryEnqueue.call(mapping: mapping)
    end

    def apply_review!(supplier_code:, variant:, quantities:, confidence_score:)
      persist_mapping!(
        supplier_code: supplier_code,
        variant: variant,
        status: "review",
        confidence_score: confidence_score,
        quantities: quantities
      )
      append_review_output!(supplier_code: supplier_code, quantities: quantities)
    end

    def persist_mapping!(supplier_code:, variant:, status:, confidence_score: nil, quantities: nil)
      mapping = @merchant.mapping_dictionaries.find_or_initialize_by(
        supplier: @supplier,
        supplier_code: supplier_code
      )

      attributes = {
        status: status,
        supplier_upload_id: @upload.id,
        last_seen: Time.current,
        confidence_score: confidence_score
      }

      if variant
        attributes[:master_sku] = variant.master_sku
        attributes[:platform_variant_id] = variant.platform_variant_id
        attributes[:platform_inventory_id] = variant.platform_inventory_id
      end

      if status.in?(%w[review mapped])
        attributes[:pending_quantity] = Review::PendingQuantity.aggregate(quantities)
      end

      mapping.assign_attributes(attributes)
      mapping.save!
      mapping
    end

    def append_review_output!(supplier_code:, quantities:)
      quantities.each do |quantity|
        @review_output << {
          "unique_code" => supplier_code,
          "quantity" => quantity
        }
      end
    end

    def confidence_from(candidate)
      return if candidate.nil?

      distance = candidate.distance.to_f
      [ 1.0 - distance, 0.0 ].max.round(4)
    end

    def finished(stage_message)
      Result.new(
        resolved_count: @resolved_count,
        unresolved_count: [ @unresolved_count, 0 ].max,
        output: @review_output,
        stage_message: stage_message
      )
    end

    def phase_three_message(unique_code_count)
      "Complete — resolved #{@resolved_count} rows (#{unique_code_count} unique codes via embedding)"
    end
  end
end
