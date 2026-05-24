"use client";

import Link from "next/link";
import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Badge,
  Spinner,
  EmptyState,
  ProgressBar,
} from "@shopify/polaris";
import { formatRelativeTime } from "../lib/format-relative-time";
import styles from "./feed-show.module.css";

function SyncStatusBadge({ status }) {
  if (status === "completed" || status === "needs_review") {
    return <Badge tone="success">completed</Badge>;
  }
  if (status === "failed") {
    return <Badge tone="critical">failed</Badge>;
  }
  if (status === "processing" || status === "pending") {
    return <Badge tone="attention">processing</Badge>;
  }
  return <Badge>{status}</Badge>;
}

function stepIcon(state) {
  if (state === "done") return "✅";
  if (state === "active") return "⏳";
  if (state === "failed") return "❌";
  return "○";
}

function isProcessing(status) {
  return status === "pending" || status === "processing";
}

export default function FeedLastSync({
  upload,
  loading,
  reviewPendingHref,
}) {
  if (loading) {
    return (
      <Card>
        <BlockStack gap="200" inlineAlign="center">
          <Spinner size="small" accessibilityLabel="Loading last sync" />
        </BlockStack>
      </Card>
    );
  }

  if (!upload) {
    return (
      <Card>
        <BlockStack gap="400">
          <Text as="h2" variant="headingMd">
            Last sync
          </Text>
          <EmptyState heading="No syncs yet">
            <p>Save your feed and run a sync to see results here.</p>
          </EmptyState>
        </BlockStack>
      </Card>
    );
  }

  const processing = isProcessing(upload.status);
  const pendingCount = upload.pending_count ?? upload.unresolved_count ?? 0;
  const resolvedCount = upload.resolved_count ?? 0;

  if (processing) {
    const percent = upload.progress_percent ?? 40;
    const steps = upload.steps ?? [];

    return (
      <Card>
        <BlockStack gap="400">
          <InlineStack gap="200" blockAlign="center">
            <Text as="h2" variant="headingMd">
              Last sync
            </Text>
            <SyncStatusBadge status={upload.status} />
          </InlineStack>
          <ProgressBar progress={percent} size="small" />
          <Text as="p" variant="bodySm" tone="subdued">
            {upload.stage_label || "Processing sheet…"}
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

  return (
    <Card>
      <BlockStack gap="300">
        <InlineStack gap="200" blockAlign="center">
          <Text as="h2" variant="headingMd">
            Last sync
          </Text>
          <SyncStatusBadge status={upload.status} />
        </InlineStack>

        <Text as="p" variant="bodyMd" tone="subdued">
          Synced: {formatRelativeTime(upload.created_at)}
        </Text>

        <InlineStack gap="400" wrap>
          <Text as="p" variant="bodyMd">
            Resolved: <strong>{resolvedCount}</strong>
          </Text>
          <InlineStack gap="100" blockAlign="center">
            <Text as="p" variant="bodyMd">
              Pending: <strong>{pendingCount}</strong>
            </Text>
            {pendingCount > 0 ? (
              <Link href={reviewPendingHref}>Review →</Link>
            ) : null}
          </InlineStack>
        </InlineStack>

        {upload.status === "failed" && upload.error_message ? (
          <Text as="p" variant="bodyMd" tone="critical">
            {upload.error_message}
          </Text>
        ) : null}
      </BlockStack>
    </Card>
  );
}
