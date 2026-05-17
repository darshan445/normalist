"use client";

import { useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  InlineGrid,
  DataTable,
  Badge,
  Banner,
} from "@shopify/polaris";
import { useAppSession } from "../lib/session-context";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { STATIC_SUPPLIERS } from "../lib/suppliers-static";
import styles from "./app-shell.module.css";

const STATS = [
  { label: "Variants", value: "128" },
  { label: "Pending Mappings", value: "4" },
  { label: "Suppliers", value: String(STATIC_SUPPLIERS.length) },
];

const RECENT_ACTIVITY = [
  { supplier: "Supplier A", when: "2hrs ago", status: "success", count: 45 },
  { supplier: "Supplier B", when: "1day ago", status: "warning", count: 4 },
  { supplier: "Supplier C", when: "3days ago", status: "success", count: 12 },
];

const PENDING_MAPPING_COUNT = 4;

function ActivityStatus({ status, count }) {
  if (status === "warning") {
    return <Badge tone="warning">{`⚠️ ${count}`}</Badge>;
  }
  return <Badge tone="success">{`✅ ${count}`}</Badge>;
}

export default function Dashboard() {
  const session = useAppSession();
  const searchParams = useSearchParams();
  const shopifyParams = pickShopifyParams(searchParams);
  const mappingsHref = shopifyNavHref("/suppliers/supplier-a#mappings", shopifyParams);

  const storeName = session?.merchant?.name || "your store";

  const rows = RECENT_ACTIVITY.map((row) => [
    row.supplier,
    row.when,
    <ActivityStatus key={row.supplier} status={row.status} count={row.count} />,
  ]);

  return (
    <BlockStack gap="500">
      <div className={styles.welcome}>
        <Text as="h1" variant="headingLg">
          Welcome, {storeName}
        </Text>
      </div>

      <InlineGrid columns={3} gap="400">
        {STATS.map((stat) => (
          <Card key={stat.label}>
            <BlockStack gap="200">
              <Text as="p" variant="bodySm" tone="subdued">
                {stat.label}
              </Text>
              <Text as="p" variant="headingXl">
                {stat.value}
              </Text>
            </BlockStack>
          </Card>
        ))}
      </InlineGrid>

      <BlockStack gap="300">
        <Text as="h2" variant="headingMd">
          Recent Activity
        </Text>
        <Card padding="0">
          <DataTable
            columnContentTypes={["text", "text", "text"]}
            headings={["Supplier", "Uploaded", "Result"]}
            rows={rows}
          />
        </Card>
      </BlockStack>

      <Banner
        tone="warning"
        action={{ content: "Review Mappings →", url: mappingsHref }}
      >
        {PENDING_MAPPING_COUNT} codes need mapping
      </Banner>
    </BlockStack>
  );
}
