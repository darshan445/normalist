"use client";

import { useMemo, useState } from "react";
import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Button,
  TextField,
  DataTable,
  Badge,
} from "@shopify/polaris";
import { CATALOG_STATS, CATALOG_VARIANTS } from "../lib/catalog-static";

function SyncStatusCell() {
  return <Badge tone="success">✅</Badge>;
}

export default function Catalog() {
  const [query, setQuery] = useState("");

  const filteredVariants = useMemo(() => {
    const term = query.trim().toLowerCase();
    if (!term) return CATALOG_VARIANTS;

    return CATALOG_VARIANTS.filter((row) => {
      const haystack = [row.product, row.variant, row.sku].join(" ").toLowerCase();
      return haystack.includes(term);
    });
  }, [query]);

  const rows = filteredVariants.map((row) => [
    row.product,
    row.variant,
    row.sku,
    <SyncStatusCell key={row.id} />,
  ]);

  return (
    <BlockStack gap="500">
      <InlineStack align="space-between" blockAlign="center">
        <Text as="h1" variant="headingLg">
          Catalog
        </Text>
        <Button variant="primary">Import CSV</Button>
      </InlineStack>

      <InlineStack align="space-between" blockAlign="center" wrap>
        <BlockStack gap="100">
          <Text as="p" variant="bodyMd" fontWeight="medium">
            {CATALOG_STATS.variantCount} variants synced
          </Text>
          <Text as="p" variant="bodySm" tone="subdued">
            Last synced: {CATALOG_STATS.lastSyncedLabel}
          </Text>
        </BlockStack>
        <Button>Sync Now</Button>
      </InlineStack>

      <TextField
        label="Search variants"
        labelHidden
        value={query}
        onChange={setQuery}
        placeholder="Search variants..."
        autoComplete="off"
      />

      <Card padding="0">
        <DataTable
          columnContentTypes={["text", "text", "text", "text"]}
          headings={["Product", "Variant", "SKU", ""]}
          rows={rows}
        />
      </Card>
    </BlockStack>
  );
}
