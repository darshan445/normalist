class CompilationJob < ApplicationJob
  include UploadFileParsable

  NeedsReviewRow = Struct.new(:supplier_code, :quantity, keyword_init: true)

  queue_as :uploads

  def perform(supplier_upload_id)
    upload = SupplierUpload.find(supplier_upload_id)
    merchant = upload.merchant
    supplier = upload.supplier

    upload.update!(status: "processing", stage: "Re-processing with updated mappings…")
    Broadcasts::UploadBroadcaster.call(upload)

    rows = parse_upload_file(upload)
    return if rows.nil?

    profile_record = merchant.supplier_profiles.find_by!(supplier: supplier)
    profile = profile_record.profile_hash

    extracted = Mapping::RowExtractor.call(rows, profile)
    lookup = Mapping::DictionaryLookup.call(
      merchant: merchant,
      supplier: supplier,
      extracted_rows: extracted
    )

    auto_match = Mapping::AutoMatcher.call(
      merchant: merchant,
      supplier: supplier,
      unresolved_rows: lookup[:unresolved]
    )

    all_resolved = lookup[:resolved] + auto_match[:resolved]
    unresolved = auto_match[:unresolved]

    needs_review = unresolved.map do |row|
      NeedsReviewRow.new(supplier_code: row.supplier_code, quantity: row.quantity)
    end

    validated = Compilation::Validator.call(merchant: merchant, resolved_rows: all_resolved)
    output = Compilation::Engine.call(
      validated_rows: validated,
      needs_review_rows: needs_review
    )

    upload.update!(
      status: "completed",
      stage: unresolved.any? ? "Complete — #{unresolved.size} row(s) still need review" : "Complete",
      output: output,
      resolved_count: all_resolved.size,
      unresolved_count: unresolved.size
    )
    Broadcasts::UploadBroadcaster.call(upload, unresolved_rows: unresolved)
  rescue StandardError => e
    upload&.update!(status: "failed", error_message: e.message, stage: "Failed")
    Broadcasts::UploadBroadcaster.call(upload) if upload
    raise
  end
end
