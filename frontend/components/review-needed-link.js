"use client";

import Link from "next/link";
import { Badge } from "@shopify/polaris";
import styles from "./review-needed-link.module.css";

export function ReviewNeededLink({ count, href }) {
  if (!count || count <= 0) {
    return <span className={styles.muted}>—</span>;
  }

  const label = `${count} need review`;

  return (
    <Link
      href={href}
      className={styles.link}
      title="Open review queue to map these supplier codes"
      aria-label={`${label}. Open review queue.`}
    >
      <span>{label}</span>
      <span aria-hidden>→</span>
    </Link>
  );
}

export function ActivityOutcomeCell({ row, reviewHref }) {
  if (row.status === "failed") {
    return <Badge tone="critical">Upload failed</Badge>;
  }

  if (row.unresolved_count > 0) {
    return <ReviewNeededLink count={row.unresolved_count} href={reviewHref} />;
  }

  if (row.status === "warning") {
    return <Badge tone="warning">Processing…</Badge>;
  }

  const resolved = row.resolved_count ?? 0;
  return <Badge tone="success">{`${resolved} mapped`}</Badge>;
}
