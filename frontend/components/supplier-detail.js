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
  Banner,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { feedIcon, canAddMoreFeeds } from "../lib/feed-helpers";
import { formatRelativeTime } from "../lib/format-relative-time";
import MappingStatsGrid from "./mapping-stats-grid";
import ChooseFeedTypeModal from "./choose-feed-type-modal";
import styles from "./supplier-detail.module.css";

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

export default function SupplierDetail({
  supplier,
  mappingStats,
  feeds,
}) {
  const searchParams = useSearchParams();
  const shopifyParams = pickShopifyParams(searchParams);
  const suppliersHref = shopifyNavHref("/suppliers", shopifyParams);
  const mappingsHref = shopifyNavHref(
    `/suppliers/${supplier.id}/mappings`,
    shopifyParams
  );
  const reviewPendingHref = shopifyNavHref(
    `/review?supplier_id=${supplier.id}`,
    shopifyParams
  );
  const reviewSuggestedHref = shopifyNavHref(
    `/review?supplier_id=${supplier.id}&suggestion=suggested`,
    shopifyParams
  );

  const [feedModalOpen, setFeedModalOpen] = useState(false);
  const usedFeedTypes = feeds.map((feed) => feed.feed_type);
  const showAddFeed = canAddMoreFeeds(usedFeedTypes);

  const stats = mappingStats ?? {
    mapped: supplier.mappedCount ?? 0,
    pending: supplier.pendingCount ?? 0,
    skipped: supplier.skippedCount ?? 0,
    review: supplier.reviewCount ?? 0,
  };

  const pendingCount = stats.pending;
  const reviewCount = stats.review;
  const mappingsTotal = stats.mapped + stats.pending + stats.skipped + stats.review;

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

      <MappingStatsGrid
        mapped={stats.mapped}
        pending={stats.pending}
        skipped={stats.skipped}
      />

      {pendingCount > 0 ? (
        <Banner tone="warning">
          <BlockStack gap="200">
            <p>
              ⚠️ {pendingCount} code{pendingCount === 1 ? "" : "s"} need your attention
            </p>
            <div>
              <Button url={reviewPendingHref}>Review pending →</Button>
            </div>
          </BlockStack>
        </Banner>
      ) : null}

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

      {reviewCount > 0 ? (
        <>
          <SectionDivider />
          <section className={styles.sectionAnchor}>
            <Card>
              <BlockStack gap="300">
                <InlineStack align="space-between" blockAlign="center" wrap>
                  <BlockStack gap="100">
                    <Text as="h2" variant="headingMd">
                      Review suggested mappings
                    </Text>
                    <Text as="p" variant="bodySm" tone="subdued">
                      {reviewCount} code{reviewCount === 1 ? "" : "s"} with AI suggestions
                      awaiting confirm or skip.
                    </Text>
                  </BlockStack>
                  <Button url={reviewSuggestedHref}>Open review queue</Button>
                </InlineStack>
              </BlockStack>
            </Card>
          </section>
        </>
      ) : null}

      <SectionDivider />

      <section>
        <Card>
          <BlockStack gap="300">
            <Text as="h2" variant="headingMd">
              Mappings
            </Text>
            {mappingsTotal === 0 ? (
              <EmptyState heading="No mappings yet">
                <p>
                  Supplier codes appear here after you upload a stock file and the
                  engine resolves or flags them.
                </p>
              </EmptyState>
            ) : (
              <Text as="p" variant="bodyMd" tone="subdued">
                {mappingsTotal} supplier code{mappingsTotal === 1 ? "" : "s"} tracked for
                this supplier. View mapped, pending, and skipped codes on the mappings
                page.
              </Text>
            )}
            <div>
              <Button url={mappingsHref} variant="primary">
                View all mappings
              </Button>
            </div>
          </BlockStack>
        </Card>
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
