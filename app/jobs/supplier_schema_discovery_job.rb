# frozen_string_literal: true

class SupplierSchemaDiscoveryJob < ApplicationJob
  queue_as :uploads

  def perform(supplier_upload_id)
    upload = SupplierUpload.find(supplier_upload_id)

    upload.update!(status: "processing", stage: "Discovering column schema…", error_message: nil)

    discovery_result = Schema::Discovery.call(upload: upload)

    if discovery_result.failure?
      fail_upload!(upload, discovery_result)
      return
    end

    run_fast_pass!(upload)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("[SupplierSchemaDiscoveryJob] Upload #{supplier_upload_id} not found")
  rescue StandardError => e
    upload&.update!(
      status: "failed",
      stage: "Failed",
      error_message: e.message
    )
    Rails.logger.error(
      "[SupplierSchemaDiscoveryJob] Failed for upload #{supplier_upload_id}: #{e.class} — #{e.message}"
    )
  end

  private

  def run_fast_pass!(upload)
    upload.update!(stage: "Matching supplier codes…")

    fast_pass = Mapping::FastPass.call(upload: upload)

    resolved_count = fast_pass.resolved_count
    unresolved_count = fast_pass.unresolved_count
    output = fast_pass.unmatched_rows
    stage_message = fast_pass.stage_message

    if fast_pass.unmatched_rows.any?
      upload.update!(stage: "Resolving unmatched codes…")
      phase_three = Mapping::UnmatchedResolver.call(
        upload: upload,
        unmatched_rows: fast_pass.unmatched_rows,
        initial_resolved_count: resolved_count,
        initial_unresolved_count: unresolved_count
      )
      resolved_count = phase_three.resolved_count
      unresolved_count = phase_three.unresolved_count
      output = phase_three.output
      stage_message = phase_three.stage_message
    end

    upload.update!(
      status: unresolved_count.zero? ? "completed" : "needs_review",
      stage: unresolved_count.zero? ? stage_message : "Review required — #{unresolved_count} code(s) need confirmation",
      error_message: nil,
      resolved_count: resolved_count,
      unresolved_count: unresolved_count,
      output: output
    )
  rescue StandardError => e
    upload.update!(status: "failed", stage: "Failed", error_message: e.message)
    raise
  end

  def fail_upload!(upload, result)
    upload.update!(
      status: "failed",
      stage: result.stage,
      error_message: result.error_message
    )
  end
end
