"use client";

import Link from "next/link";
import {
  Text,
  Card,
  BlockStack,
  EmptyState,
  DataTable,
  Spinner,
} from "@shopify/polaris";
import { formatRelativeTime } from "../lib/format-relative-time";

function statusCell(status, pendingCount) {
  if (status === "failed") return "❌ Failed";
  if (status === "processing" || status === "pending") return "⏳ Processing";
  if (pendingCount > 0) return "⚠️ Done";
  return "✅";
}

function PendingCell({ count, reviewPendingHref }) {
  if (!count || count <= 0) {
    return "0";
  }

  return (
    <Link href={reviewPendingHref}>
      {count} →
    </Link>
  );
}

export default function FeedSyncHistory({
  syncs,
  loading,
  reviewPendingHref,
}) {
  const rows = (syncs ?? []).map((sync) => {
    const pending = sync.pending_count ?? 0;
    const total = sync.total_codes ?? "—";

    return [
      formatRelativeTime(sync.created_at),
      total,
      sync.resolved_count ?? 0,
      <PendingCell key={`pending-${sync.id}`} count={pending} reviewPendingHref={reviewPendingHref} />,
      statusCell(sync.status, pending),
    ];
  });

  return (
    <Card>
      <BlockStack gap="400">
        <Text as="h2" variant="headingMd">
          Sync history
        </Text>

        {loading ? (
          <BlockStack gap="200" inlineAlign="center">
            <Spinner size="small" accessibilityLabel="Loading sync history" />
          </BlockStack>
        ) : rows.length === 0 ? (
          <EmptyState heading="No sync history yet">
            <p>Run a sync to see history here.</p>
          </EmptyState>
        ) : (
          <DataTable
            columnContentTypes={["text", "numeric", "numeric", "numeric", "text"]}
            headings={["Date", "Codes", "Resolved", "Pending", "Status"]}
            rows={rows}
          />
        )}
      </BlockStack>
    </Card>
  );
}
