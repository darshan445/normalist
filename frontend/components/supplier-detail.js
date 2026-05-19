"use client";

import { useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Button,
  Badge,
  EmptyState,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { feedIcon, canAddMoreFeeds } from "../lib/feed-helpers";
import { formatRelativeTime } from "../lib/format-relative-time";
import MappingRow from "./mapping-row";
import ChooseFeedTypeModal from "./choose-feed-type-modal";
import styles from "./supplier-detail.module.css";
import mappingStyles from "./mappings.module.css";

function SectionDivider() {
  return <hr className={styles.sectionDivider} />;
}

function FeedStatusBadge({ status }) {
  if (status === "active") {
    return <Badge tone="success">active</Badge>;
  }
  if (status === "error") {
    return <Badge tone="critical">error</Badge>;
  }
  return <Badge>{status}</Badge>;
}

function MappingStatusBadge({ status }) {
  if (status === "mapped") {
    return <Badge tone="success">mapped</Badge>;
  }
  if (status === "review") {
    return <Badge tone="attention">review</Badge>;
  }
  if (status === "pending") {
    return <Badge tone="warning">pending</Badge>;
  }
  if (status === "skipped") {
    return <Badge>skipped</Badge>;
  }
  return <Badge>{status}</Badge>;
}

function toMappingRowProps(row) {
  return {
    id: row.id,
    code: row.supplier_code,
    quantity: row.quantity ?? "—",
  };
}

export default function SupplierDetail({
  supplier,
  feeds,
  activeMappings,
  activeMappingsTotal,
  pendingMappings,
  reviewMappings = [],
}) {
  const searchParams = useSearchParams();
  const shopifyParams = pickShopifyParams(searchParams);
  const suppliersHref = shopifyNavHref("/suppliers", shopifyParams);
  const [feedModalOpen, setFeedModalOpen] = useState(false);
  const usedFeedTypes = feeds.map((feed) => feed.feed_type);
  const showAddFeed = canAddMoreFeeds(usedFeedTypes);

  const pendingCount = pendingMappings.length;
  const reviewCount = reviewMappings.length;

  return (
    <BlockStack gap="500">
      <BlockStack gap="200">
        <Link href={suppliersHref} className={styles.backLink}>
          ← Suppliers
        </Link>
        <InlineStack align="space-between" blockAlign="center">
          <Text as="h1" variant="headingLg">
            {supplier.name}
          </Text>
          <Button variant="plain" accessibilityLabel="Supplier actions">
            ···
          </Button>
        </InlineStack>
      </BlockStack>

      <SectionDivider />

      <section>
        <BlockStack gap="300">
          <InlineStack align="space-between" blockAlign="center">
            <Text as="h2" variant="headingMd">
              Feeds
            </Text>
            {showAddFeed ? (
              <Button size="slim" onClick={() => setFeedModalOpen(true)}>
                + Add Feed
              </Button>
            ) : null}
          </InlineStack>

          {feeds.length === 0 ? (
            <Card>
              <EmptyState
                heading="No feeds yet"
                action={
                  showAddFeed
                    ? { content: "Add feed", onAction: () => setFeedModalOpen(true) }
                    : undefined
                }
              >
                <p>Add a file upload or Google Sheets feed for this supplier.</p>
              </EmptyState>
            </Card>
          ) : (
            <div className={styles.feedCard}>
              {feeds.map((feed) => {
                const feedHref = shopifyNavHref(
                  `/suppliers/${supplier.id}/feeds/${feed.id}`,
                  shopifyParams
                );

                return (
                  <Link
                    key={feed.id}
                    href={feedHref}
                    className={`${styles.feedRow} ${styles.feedRowLink}`}
                  >
                    <div className={styles.feedMain}>
                      <span className={styles.feedIcon} aria-hidden>
                        {feedIcon(feed.feed_type)}
                      </span>
                      <div className={styles.feedMeta}>
                        <Text as="p" variant="bodyMd" fontWeight="semibold">
                          {feed.name}
                        </Text>
                        {feed.last_upload_at ? (
                          <>
                            <Text as="p" variant="bodySm" tone="subdued">
                              Last upload: {formatRelativeTime(feed.last_upload_at)}
                            </Text>
                            {feed.latest_upload?.status ? (
                              <Text as="p" variant="bodySm" tone="subdued">
                                Upload: {feed.latest_upload.status}
                                {feed.latest_upload.stage
                                  ? ` — ${feed.latest_upload.stage}`
                                  : ""}
                              </Text>
                            ) : null}
                          </>
                        ) : feed.feed_type === "google_sheets" && feed.url ? (
                          <Text as="p" variant="bodySm" tone="subdued">
                            {feed.url}
                          </Text>
                        ) : (
                          <Text as="p" variant="bodySm" tone="subdued">
                            No uploads yet
                          </Text>
                        )}
                      </div>
                    </div>
                    <FeedStatusBadge status={feed.status} />
                  </Link>
                );
              })}
            </div>
          )}
        </BlockStack>
      </section>

      {pendingCount > 0 ? (
        <>
          <SectionDivider />
          <section id="mappings" className={styles.sectionAnchor}>
            <BlockStack gap="300">
              <InlineStack gap="200" blockAlign="center">
                <Text as="h2" variant="headingMd">
                  Pending Mappings
                </Text>
                <Text as="span" variant="bodyMd" tone="caution">
                  ⚠️ {pendingCount}
                </Text>
              </InlineStack>

              <Card padding="0">
                <BlockStack gap="0">
                  {pendingMappings.map((mapping) => (
                    <MappingRow
                      key={mapping.id}
                      mapping={toMappingRowProps(mapping)}
                    />
                  ))}
                </BlockStack>
              </Card>

              <div className={mappingStyles.footerAction}>
                <Button variant="primary" size="large">
                  Confirm All Mappings
                </Button>
              </div>
            </BlockStack>
          </section>
        </>
      ) : null}

      {reviewCount > 0 ? (
        <>
          <SectionDivider />
          <section className={styles.sectionAnchor}>
            <BlockStack gap="300">
              <InlineStack align="space-between" blockAlign="center">
                <InlineStack gap="200" blockAlign="center">
                  <Text as="h2" variant="headingMd">
                    Review suggested mappings
                  </Text>
                  <Text as="span" variant="bodyMd" tone="caution">
                    {reviewCount}
                  </Text>
                </InlineStack>
                <Button
                  url={shopifyNavHref(
                    `/review?supplier_id=${supplier.id}`,
                    shopifyParams
                  )}
                >
                  Open review queue
                </Button>
              </InlineStack>

              <Card padding="0">
                <BlockStack gap="0">
                  {reviewMappings.slice(0, 5).map((mapping) => (
                    <div key={mapping.id} className={styles.activeMappingRow}>
                      <Text as="span" variant="bodyMd">
                        {mapping.supplier_code} → {mapping.master_sku || "—"}
                      </Text>
                      <span />
                      <MappingStatusBadge status={mapping.status} />
                    </div>
                  ))}
                </BlockStack>
              </Card>
              {reviewCount > 5 ? (
                <Text as="p" variant="bodySm" tone="subdued">
                  Showing 5 of {reviewCount} — open the review queue to confirm or reject.
                </Text>
              ) : null}
            </BlockStack>
          </section>
        </>
      ) : null}

      <SectionDivider />

      <section>
        <BlockStack gap="300">
          <InlineStack align="space-between" blockAlign="center">
            <Text as="h2" variant="headingMd">
              Mapped
            </Text>
            <Text as="p" variant="bodySm" tone="subdued">
              Total {activeMappingsTotal}
            </Text>
          </InlineStack>

          {activeMappings.length === 0 ? (
            <Card>
              <EmptyState heading="No active mappings yet">
                <p>
                  Mappings appear here after supplier codes are resolved or confirmed.
                </p>
              </EmptyState>
            </Card>
          ) : (
            <Card padding="0">
              {activeMappings.map((row) => (
                <div key={row.id} className={styles.activeMappingRow}>
                  <Text as="span" variant="bodyMd">
                    {row.supplier_code} → {row.master_sku || "──────────"}
                  </Text>
                  <span />
                  <MappingStatusBadge status={row.status} />
                </div>
              ))}
            </Card>
          )}
        </BlockStack>
      </section>

      <ChooseFeedTypeModal
        open={feedModalOpen}
        onClose={() => setFeedModalOpen(false)}
        supplierId={supplier.id}
        shopifyParams={shopifyParams}
        existingFeeds={feeds}
      />
    </BlockStack>
  );
}
