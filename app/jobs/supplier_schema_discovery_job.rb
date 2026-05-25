# frozen_string_literal: true

class SupplierSchemaDiscoveryJob < ApplicationJob
  queue_as :uploads

  retry_on ActiveRecord::RecordNotFound, wait: 5.seconds, attempts: 5
  retry_on ActiveStorage::FileNotFoundError, wait: 5.seconds, attempts: 5

  def perform(supplier_upload_id)
    upload = SupplierUpload.find(supplier_upload_id)

    upload.update!(status: "processing", stage: "parsing", error_message: nil)

    discovery_result = Schema::Discovery.call(upload: upload)

    if discovery_result.failure?
      fail_upload!(upload, discovery_result)
      return
    end

    upload.update!(
      row_count: discovery_result.row_count,
      stage: discovery_result.profile_stage
    )

    run_fast_pass!(upload)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("[SupplierSchemaDiscoveryJob] Upload #{supplier_upload_id} not found")
    raise
  rescue ActiveStorage::FileNotFoundError
    raise
  rescue StandardError => e
    upload&.update!(
      status: "failed",
      stage: "failed",
      error_message: e.message
    )
    touch_feed_last_synced!(upload) if upload
    Rails.logger.error(
      "[SupplierSchemaDiscoveryJob] Failed for upload #{supplier_upload_id}: #{e.class} — #{e.message}"
    )
  end

  private

  def run_fast_pass!(upload)
    upload.update!(stage: "resolving")

    fast_pass = Mapping::FastPass.call(upload: upload)

    resolved_count = fast_pass.resolved_count
    unresolved_count = fast_pass.unresolved_count
    output = fast_pass.unmatched_rows
    stage_message = fast_pass.stage_message

    if fast_pass.unmatched_rows.any?
      upload.update!(stage: "resolving")
      phase_three = Mapping::UnmatchedResolver.call(
        upload: upload,
        unmatched_rows: fast_pass.unmatched_rows,
        code_metrics: fast_pass.code_metrics
      )
      resolved_count = phase_three.resolved_count
      unresolved_count = phase_three.unresolved_count
      output = phase_three.output
      stage_message = phase_three.stage_message
    end

    upload.update!(
      status: unresolved_count.zero? ? "completed" : "needs_review",
      stage: "complete",
      error_message: nil,
      unique_code_count: fast_pass.unique_code_count,
      resolved_count: resolved_count,
      unresolved_count: unresolved_count,
      output: output
    )

    touch_feed_last_synced!(upload)
  rescue StandardError => e
    upload.update!(status: "failed", stage: "failed", error_message: e.message)
    touch_feed_last_synced!(upload)
    raise
  end

  def fail_upload!(upload, result)
    upload.update!(
      status: "failed",
      stage: "failed",
      error_message: result.error_message
    )
    touch_feed_last_synced!(upload)
  end

  def touch_feed_last_synced!(upload)
    feed = upload.feed
    return unless feed&.google_sheets?

    feed.update!(last_synced_at: Time.current)
  end
end
