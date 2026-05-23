"use client";

import {
  Text,
  Card,
  BlockStack,
  EmptyState,
  DataTable,
  Spinner,
} from "@shopify/polaris";
import { formatRelativeTime } from "../lib/format-relative-time";
import { ReviewNeededLink } from "./review-needed-link";

function statusCell(status, pendingCount) {
  if (status === "failed") return "❌ Failed";
  if (status === "processing" || status === "pending") return "⏳ Processing";
  if (pendingCount > 0) return "⚠️ Done";
  return "✅";
}

export default function FeedUploadHistory({
  uploads,
  loading,
  reviewPendingHref,
}) {
  const rows = (uploads ?? []).map((upload) => {
    const pending = upload.pending_count ?? 0;
    const total = upload.total_codes ?? "—";

    const pendingCell = (
      <ReviewNeededLink count={pending} href={reviewPendingHref} />
    );

    return [
      formatRelativeTime(upload.created_at),
      total,
      upload.resolved_count ?? 0,
      pendingCell,
      statusCell(upload.status, pending),
    ];
  });

  return (
    <Card>
      <BlockStack gap="400">
        <Text as="h2" variant="headingMd">
          Upload history
        </Text>

        {loading ? (
          <BlockStack gap="200" inlineAlign="center">
            <Spinner size="small" accessibilityLabel="Loading history" />
          </BlockStack>
        ) : rows.length === 0 ? (
          <EmptyState heading="No uploads yet">
            <p>Upload a CSV or Excel stock file to see history here.</p>
          </EmptyState>
        ) : (
          <DataTable
            columnContentTypes={["text", "numeric", "numeric", "numeric", "text"]}
            headings={["Date", "Codes", "Resolved", "Need review", "Status"]}
            rows={rows}
          />
        )}
      </BlockStack>
    </Card>
  );
}
