"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  InlineGrid,
  DataTable,
  Banner,
  Spinner,
  EmptyState,
} from "@shopify/polaris";
import { useAppSession } from "../lib/session-context";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { fetchDashboard } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import { formatRelativeTime } from "../lib/format-relative-time";
import { ActivityOutcomeCell } from "./review-needed-link";
import TrialBanner from "./trial-banner";
import styles from "./app-shell.module.css";

function RecentActivityEmpty({ suppliersCount, suppliersHref }) {
  if (suppliersCount === 0) {
    return (
      <EmptyState
        heading="No suppliers yet"
        action={{
          content: "Add supplier",
          url: `${suppliersHref}${suppliersHref.includes("?") ? "&" : "?"}create=1`,
        }}
      >
        <p>Create a supplier, then upload a stock file to see activity here.</p>
      </EmptyState>
    );
  }

  return (
    <EmptyState heading="No uploads yet">
      <p>
        Upload a supplier stock file from a supplier page to track sync results here.
      </p>
      <p>
        <Link href={suppliersHref}>View suppliers →</Link>
      </p>
    </EmptyState>
  );
}

export default function Dashboard() {
  const session = useAppSession();
  const searchParams = useSearchParams();
  const { shop, embedded } = pickShopifyParams(searchParams);
  const shopifyParams = pickShopifyParams(searchParams);

  const [dashboard, setDashboard] = useState(null);
  const [loadState, setLoadState] = useState({ status: "loading", error: null });

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoadState({ status: "loading", error: null });

      try {
        const sessionToken = embedded ? await fetchSessionToken() : null;
        const result = await fetchDashboard({ shop, sessionToken });

        if (cancelled) return;

        if (!result.ok) {
          setLoadState({
            status: "error",
            error: result.data?.message || "Could not load dashboard.",
          });
          return;
        }

        setDashboard(result.data);
        setLoadState({ status: "ready", error: null });
      } catch (error) {
        if (cancelled) return;
        setLoadState({ status: "error", error: error.message });
      }
    }

    load();

    return () => {
      cancelled = true;
    };
  }, [shop, embedded]);

  const storeName =
    dashboard?.merchant?.name || session?.merchant?.name || "your store";

  const stats = dashboard?.stats ?? {
    variants_count: 0,
    pending_mappings_count: 0,
    suppliers_count: 0,
  };

  const recentActivity = dashboard?.recent_activity ?? [];

  const suppliersHref = shopifyNavHref("/suppliers", shopifyParams);
  const catalogHref = shopifyNavHref("/catalog", shopifyParams);

  const statCards = [
    {
      label: "Variants",
      value: stats.variants_count,
      hint: stats.variants_count === 0 ? "Your catalog is empty" : null,
      href: stats.variants_count === 0 ? catalogHref : null,
    },
    {
      label: "Pending Mappings",
      value: stats.pending_mappings_count,
      hint: null,
      href: null,
    },
    {
      label: "Suppliers",
      value: stats.suppliers_count,
      hint: null,
      href: stats.suppliers_count === 0 ? suppliersHref : null,
    },
  ];

  const activityRows = recentActivity.map((row) => {
    const supplierDetailHref = shopifyNavHref(
      `/suppliers/${row.supplier_id}`,
      shopifyParams
    );
    const reviewHref = shopifyNavHref(
      `/review?supplier_id=${row.supplier_id}`,
      shopifyParams
    );
    return [
      <Link key={`${row.id}-supplier`} href={supplierDetailHref}>
        {row.supplier_name}
      </Link>,
      formatRelativeTime(row.uploaded_at),
      <span key={`${row.id}-result`}>
        <ActivityOutcomeCell row={row} reviewHref={reviewHref} />
      </span>,
    ];
  });

  if (loadState.status === "loading") {
    return (
      <BlockStack gap="500" inlineAlign="center">
        <Spinner accessibilityLabel="Loading dashboard" size="large" />
        <Text as="p" variant="bodyMd" tone="subdued">
          Loading dashboard…
        </Text>
      </BlockStack>
    );
  }

  return (
    <BlockStack gap="500">
      <TrialBanner />

      {loadState.status === "error" ? (
        <Banner tone="critical" title="Could not load dashboard">
          <p>{loadState.error}</p>
        </Banner>
      ) : null}

      <div className={styles.welcome}>
        <Text as="h1" variant="headingLg">
          Welcome, {storeName}
        </Text>
      </div>

      <InlineGrid columns={3} gap="400">
        {statCards.map((stat) => (
          <Card key={stat.label}>
            <BlockStack gap="200">
              <Text as="p" variant="bodySm" tone="subdued">
                {stat.label}
              </Text>
              <Text as="p" variant="headingXl">
                {stat.value}
              </Text>
              {stat.hint ? (
                <Text as="p" variant="bodySm" tone="subdued">
                  {stat.href ? (
                    <Link href={stat.href}>{stat.hint}</Link>
                  ) : (
                    stat.hint
                  )}
                </Text>
              ) : null}
            </BlockStack>
          </Card>
        ))}
      </InlineGrid>

      <BlockStack gap="300">
        <Text as="h2" variant="headingMd">
          Recent Activity
        </Text>
        <Card padding={activityRows.length > 0 ? "0" : undefined}>
          {activityRows.length > 0 ? (
            <DataTable
              columnContentTypes={["text", "text", "text"]}
              headings={["Supplier", "Uploaded", "Outcome"]}
              rows={activityRows}
            />
          ) : (
            <RecentActivityEmpty
              suppliersCount={stats.suppliers_count}
              suppliersHref={suppliersHref}
            />
          )}
        </Card>
      </BlockStack>

      {stats.pending_mappings_count === 0 && stats.suppliers_count > 0 ? (
        <Banner tone="success">
          All supplier codes are mapped — you&apos;re up to date.
        </Banner>
      ) : null}
    </BlockStack>
  );
}

