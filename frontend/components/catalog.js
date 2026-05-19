"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  TextField,
  DataTable,
  Spinner,
  Banner,
  EmptyState,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { fetchCatalog } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import { formatRelativeTime } from "../lib/format-relative-time";

export default function Catalog() {
  const searchParams = useSearchParams();
  const { shop, embedded } = pickShopifyParams(searchParams);

  const [query, setQuery] = useState("");
  const [debouncedQuery, setDebouncedQuery] = useState("");
  const [catalog, setCatalog] = useState(null);
  const [loadState, setLoadState] = useState({ status: "loading", error: null });

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedQuery(query.trim()), 300);
    return () => clearTimeout(timer);
  }, [query]);

  const loadCatalog = useCallback(async () => {
    setLoadState({ status: "loading", error: null });

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const path =
        debouncedQuery.length > 0
          ? `/api/v1/catalog?q=${encodeURIComponent(debouncedQuery)}`
          : "/api/v1/catalog";
      const result = await fetchCatalog(path, { shop, sessionToken });

      if (!result.ok) {
        setLoadState({
          status: "error",
          error: result.data?.message || "Could not load catalog.",
        });
        return;
      }

      setCatalog(result.data);
      setLoadState({ status: "ready", error: null });
    } catch (error) {
      setLoadState({ status: "error", error: error.message });
    }
  }, [shop, embedded, debouncedQuery]);

  useEffect(() => {
    loadCatalog();
  }, [loadCatalog]);

  const variants = catalog?.variants ?? [];
  const stats = catalog?.stats ?? { variants_count: 0, catalog_synced_at: null };

  const rows = useMemo(
    () =>
      variants.map((row) => [
        row.product_title,
        row.variant_title,
        row.master_sku,
      ]),
    [variants]
  );

  const lastSyncedLabel = stats.catalog_synced_at
    ? formatRelativeTime(stats.catalog_synced_at)
    : null;

  return (
    <BlockStack gap="500">
      <Text as="h1" variant="headingLg">
        Catalog
      </Text>

      {loadState.status === "error" ? (
        <Banner tone="critical" title="Could not load catalog">
          <p>{loadState.error}</p>
        </Banner>
      ) : null}

      <BlockStack gap="100">
        <Text as="p" variant="bodyMd" fontWeight="medium">
          {stats.variants_count} variant{stats.variants_count === 1 ? "" : "s"}
        </Text>
        {lastSyncedLabel ? (
          <Text as="p" variant="bodySm" tone="subdued">
            Last synced: {lastSyncedLabel}
          </Text>
        ) : null}
      </BlockStack>

      <TextField
        label="Search variants"
        labelHidden
        value={query}
        onChange={setQuery}
        placeholder="Search variants…"
        autoComplete="off"
        disabled={loadState.status === "loading" && !catalog}
      />

      {loadState.status === "loading" && !catalog ? (
        <BlockStack gap="300" inlineAlign="center">
          <Spinner accessibilityLabel="Loading catalog" />
          <Text as="p" variant="bodyMd" tone="subdued">
            Loading catalog…
          </Text>
        </BlockStack>
      ) : stats.variants_count === 0 && !debouncedQuery ? (
        <Card>
          <EmptyState heading="No variants in your catalog">
            <p>
              Variants will appear here once your Shopify catalog is synced to
              NormaList.
            </p>
          </EmptyState>
        </Card>
      ) : rows.length === 0 ? (
        <Card>
          <EmptyState heading="No matching variants">
            <p>Try a different search term.</p>
          </EmptyState>
        </Card>
      ) : (
        <Card padding="0">
          <DataTable
            columnContentTypes={["text", "text", "text"]}
            headings={["Product", "Variant", "SKU"]}
            rows={rows}
          />
        </Card>
      )}
    </BlockStack>
  );
}
