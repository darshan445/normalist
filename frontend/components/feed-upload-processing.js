"use client";

import Link from "next/link";
import { Text, Card, BlockStack, InlineStack, Button, Banner, ProgressBar } from "@shopify/polaris";
import styles from "./feed-show.module.css";

function stepIcon(state) {
  if (state === "done") return "✅";
  if (state === "active") return "⏳";
  if (state === "failed") return "❌";
  return "○";
}

function isProcessing(status) {
  return status === "pending" || status === "processing";
}

export default function FeedUploadProcessing({
  upload,
  reviewPendingHref,
  onTryAgain,
}) {
  if (!upload) return null;

  const processing = isProcessing(upload.status);
  const completed = upload.status === "completed" || upload.status === "needs_review";
  const failed = upload.status === "failed";
  const pendingCount = upload.pending_count ?? upload.unresolved_count ?? 0;
  const resolvedCount = upload.resolved_count ?? 0;
  const totalCodes = upload.total_codes ?? upload.row_count;

  if (!processing && !completed && !failed) return null;

  if (processing) {
    const percent = upload.progress_percent ?? 40;
    const steps = upload.steps ?? [];

    return (
      <Card>
        <BlockStack gap="400">
          <Text as="h2" variant="headingMd">
            Processing your file…
          </Text>
          <ProgressBar progress={percent} size="small" />
          <Text as="p" variant="bodySm" tone="subdued">
            {upload.stage_label || "Processing"}
          </Text>
          {steps.length > 0 ? (
            <ul className={styles.stepList}>
              {steps.map((step) => (
                <li key={step.key} className={styles.stepItem}>
                  <span className={styles.stepIcon} aria-hidden>
                    {stepIcon(step.state)}
                  </span>
                  <Text as="span" variant="bodyMd">
                    {step.label}
                  </Text>
                </li>
              ))}
            </ul>
          ) : null}
        </BlockStack>
      </Card>
    );
  }

  if (failed) {
    return (
      <Card>
        <BlockStack gap="300">
          <Banner tone="critical" title="Upload failed">
            <p>{upload.error_message || "Something went wrong while processing this file."}</p>
          </Banner>
          <div>
            <Button onClick={onTryAgain}>Try again</Button>
          </div>
        </BlockStack>
      </Card>
    );
  }

  if (completed) {
    const hasPending = pendingCount > 0;

    return (
      <Card>
        <BlockStack gap="300">
          <Banner tone={hasPending ? "warning" : "success"} title="Upload complete">
            <BlockStack gap="200">
              <p>
                {totalCodes != null
                  ? `${totalCodes} code${totalCodes === 1 ? "" : "s"} in file`
                  : "File processed"}
                {" · "}
                {resolvedCount} resolved
              </p>
              <p>
                {hasPending
                  ? `${pendingCount} code${pendingCount === 1 ? "" : "s"} need your attention`
                  : "0 need attention"}
              </p>
            </BlockStack>
          </Banner>
          {hasPending ? (
            <InlineStack>
              <Button url={reviewPendingHref}>Review pending →</Button>
            </InlineStack>
          ) : null}
        </BlockStack>
      </Card>
    );
  }

  return null;
}
