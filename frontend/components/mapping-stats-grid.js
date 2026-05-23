"use client";

import { Text } from "@shopify/polaris";
import styles from "./mapping-stats-grid.module.css";

export default function MappingStatsGrid({
  mapped = 0,
  pending = 0,
  skipped = 0,
  compact = false,
}) {
  return (
    <div className={compact ? styles.gridCompact : styles.grid} role="group" aria-label="Mapping counts">
      <div className={styles.cell}>
        <Text as="p" variant={compact ? "bodySm" : "bodyMd"} tone="subdued">
          Mapped
        </Text>
        <Text as="p" variant={compact ? "headingSm" : "headingMd"}>
          {mapped}
        </Text>
      </div>
      <div className={styles.cell}>
        <Text as="p" variant={compact ? "bodySm" : "bodyMd"} tone="subdued">
          Pending
        </Text>
        <Text as="p" variant={compact ? "headingSm" : "headingMd"}>
          {pending}
        </Text>
      </div>
      <div className={styles.cell}>
        <Text as="p" variant={compact ? "bodySm" : "bodyMd"} tone="subdued">
          Skipped
        </Text>
        <Text as="p" variant={compact ? "headingSm" : "headingMd"}>
          {skipped}
        </Text>
      </div>
    </div>
  );
}
