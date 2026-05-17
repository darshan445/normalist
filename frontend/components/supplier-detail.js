"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Button,
  Badge,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { supplierDetailData } from "../lib/supplier-detail-static";
import { pendingMappingsForSupplier } from "../lib/mappings-static";
import MappingRow from "./mapping-row";
import styles from "./supplier-detail.module.css";
import mappingStyles from "./mappings.module.css";

function SectionDivider() {
  return <hr className={styles.sectionDivider} />;
}

function FeedStatusBadge({ status }) {
  if (status === "coming_soon") {
    return (
      <Text as="span" variant="bodySm" tone="subdued">
        🔜
      </Text>
    );
  }
  return <Badge tone="success">active</Badge>;
}

function ActiveMappingStatus({ status }) {
  if (status === "skipped") {
    return <Badge>skipped</Badge>;
  }
  return <Badge tone="success">active</Badge>;
}

export default function SupplierDetail({ supplier }) {
  const searchParams = useSearchParams();
  const shopifyParams = pickShopifyParams(searchParams);
  const suppliersHref = shopifyNavHref("/suppliers", shopifyParams);

  const { feeds, columnProfile, activeMappings, activeMappingTotal } =
    supplierDetailData(supplier);
  const pendingMappings = pendingMappingsForSupplier(supplier.id);
  const pendingCount = pendingMappings.length;

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
            <Button size="slim">+ Add Feed</Button>
          </InlineStack>

          <div className={styles.feedCard}>
            {feeds.map((feed) => (
              <div
                key={feed.id}
                className={`${styles.feedRow} ${feed.status === "coming_soon" ? styles.feedRowMuted : ""}`}
              >
                <div className={styles.feedMain}>
                  <span className={styles.feedIcon} aria-hidden>
                    {feed.icon}
                  </span>
                  <div className={styles.feedMeta}>
                    <Text as="p" variant="bodyMd" fontWeight="semibold">
                      {feed.name}
                    </Text>
                    {feed.status === "active" ? (
                      <>
                        <Text as="p" variant="bodySm" tone="subdued">
                          Last upload: {feed.lastUpload}
                        </Text>
                        <Text as="p" variant="bodySm" tone="subdued">
                          {feed.syncedCount} synced · {feed.pendingCount} pending
                        </Text>
                      </>
                    ) : null}
                  </div>
                </div>
                <div className={styles.feedActions}>
                  <FeedStatusBadge status={feed.status} />
                  {feed.uploadEnabled ? (
                    <Button size="slim" variant="primary">
                      Upload Now
                    </Button>
                  ) : null}
                </div>
              </div>
            ))}
          </div>
        </BlockStack>
      </section>

      <SectionDivider />

      <section>
        <BlockStack gap="300">
          <Text as="h2" variant="headingMd">
            Column Profile
          </Text>
          <Card padding="0">
            <div className={styles.profileRow}>
              <Text as="span" variant="bodyMd">
                SKU column:
              </Text>
              <InlineStack gap="200" blockAlign="center">
                <Text as="span" variant="bodyMd" fontWeight="medium">
                  {columnProfile.skuColumn}
                </Text>
                <span aria-hidden>✅</span>
              </InlineStack>
            </div>
            <div className={styles.profileRow}>
              <Text as="span" variant="bodyMd">
                Qty column:
              </Text>
              <InlineStack gap="200" blockAlign="center">
                <Text as="span" variant="bodyMd" fontWeight="medium">
                  {columnProfile.quantityColumn}
                </Text>
                <span aria-hidden>✅</span>
              </InlineStack>
            </div>
            <div className={styles.profileFooter}>
              <Text as="p" variant="bodySm" tone="subdued">
                {columnProfile.source}
              </Text>
            </div>
          </Card>
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
                    <MappingRow key={mapping.id} mapping={mapping} />
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

      <SectionDivider />

      <section>
        <BlockStack gap="300">
          <InlineStack align="space-between" blockAlign="center">
            <Text as="h2" variant="headingMd">
              Active Mappings
            </Text>
            <Text as="p" variant="bodySm" tone="subdued">
              Total {activeMappingTotal}
            </Text>
          </InlineStack>

          <Card padding="0">
            {activeMappings.map((row) => (
              <div key={row.supplierCode} className={styles.activeMappingRow}>
                <Text as="span" variant="bodyMd">
                  {row.supplierCode} → {row.masterSku || "──────────"}
                </Text>
                <span />
                <ActiveMappingStatus status={row.status} />
              </div>
            ))}
          </Card>
        </BlockStack>
      </section>
    </BlockStack>
  );
}
