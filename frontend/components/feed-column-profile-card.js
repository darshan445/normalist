"use client";

import { Text, Card, BlockStack, InlineStack, Badge } from "@shopify/polaris";
import { formatRelativeTime } from "../lib/format-relative-time";
import styles from "./feed-show.module.css";

export default function FeedColumnProfileCard({ profile }) {
  if (profile?.cached) {
    return (
      <Card>
        <BlockStack gap="300">
          <InlineStack align="space-between" blockAlign="center">
            <Text as="h2" variant="headingMd">
              Column profile
            </Text>
            <Badge tone="success">cached</Badge>
          </InlineStack>
          <div className={styles.profileGrid}>
            <Text as="span" variant="bodyMd" tone="subdued">
              SKU column
            </Text>
            <Text as="span" variant="bodyMd" fontWeight="semibold">
              {profile.sku_column_name}
            </Text>
            <Text as="span" variant="bodyMd" tone="subdued">
              Qty column
            </Text>
            <Text as="span" variant="bodyMd" fontWeight="semibold">
              {profile.quantity_column_name}
            </Text>
            {profile.last_used_at ? (
              <>
                <Text as="span" variant="bodyMd" tone="subdued">
                  Last used
                </Text>
                <Text as="span" variant="bodyMd">
                  {formatRelativeTime(profile.last_used_at)}
                </Text>
              </>
            ) : null}
          </div>
        </BlockStack>
      </Card>
    );
  }

  return (
    <Card>
      <BlockStack gap="200">
        <InlineStack align="space-between" blockAlign="center">
          <Text as="h2" variant="headingMd">
            Column profile
          </Text>
          <Badge>not set yet</Badge>
        </InlineStack>
        <Text as="p" variant="bodyMd" tone="subdued">
          AI will detect columns on first upload automatically.
        </Text>
      </BlockStack>
    </Card>
  );
}
