class ProcessSupplierFileJob < ApplicationJob
  include UploadFileParsable

  queue_as :uploads

  def perform(supplier_upload_id)
    upload = SupplierUpload.find(supplier_upload_id)
    merchant = upload.merchant
    supplier = upload.supplier

    upload.update!(status: "processing", stage: "Parsing file…")
    Broadcasts::UploadBroadcaster.call(upload)

    rows = parse_upload_file(upload)
    return if rows.nil?

    upload.update!(stage: "Detecting columns…")
    Broadcasts::UploadBroadcaster.call(upload)

    profile = Ai::ProfileInterpreter.call(
      merchant: merchant,
      supplier: supplier,
      rows: rows
    )

    upload.update!(stage: "Matching supplier codes…")
    Broadcasts::UploadBroadcaster.call(upload)

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

    unresolved.each do |row|
      row.mapping_dictionary.update!(status: "pending", last_seen: Time.current)
    end

    if unresolved.any?
      upload.update!(
        status: "awaiting_mapping",
        stage: "Manual mapping required",
        resolved_count: all_resolved.size,
        unresolved_count: unresolved.size
      )
      Broadcasts::UploadBroadcaster.call(upload, unresolved_rows: unresolved)
    else
      compile_and_finish(upload, merchant, all_resolved, [])
    end
  rescue StandardError => e
    upload&.update!(status: "failed", error_message: e.message, stage: "Failed")
    Broadcasts::UploadBroadcaster.call(upload) if upload
    raise
  end

  private

  def compile_and_finish(upload, merchant, resolved_rows, needs_review_rows)
    upload.update!(stage: "Compiling output…")
    Broadcasts::UploadBroadcaster.call(upload)

    validated = Compilation::Validator.call(merchant: merchant, resolved_rows: resolved_rows)
    output = Compilation::Engine.call(
      validated_rows: validated,
      needs_review_rows: needs_review_rows
    )

    upload.update!(
      status: "completed",
      stage: "Complete",
      output: output,
      resolved_count: resolved_rows.size,
      unresolved_count: needs_review_rows.size
    )
    Broadcasts::UploadBroadcaster.call(upload)
  end
end
