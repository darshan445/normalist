"use client";

import { useCallback, useEffect, useState } from "react";
import { TextField, Text, BlockStack } from "@shopify/polaris";
import { fetchCatalog } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import styles from "./review-queue.module.css";

export function variantLabel(variant) {
  const title = [variant.product_title, variant.variant_title].filter(Boolean).join(" / ");
  return `${variant.master_sku} — ${title}`;
}

export default function VariantPicker({ shop, embedded, disabled, onSelect }) {
  const [query, setQuery] = useState("");
  const [debouncedQuery, setDebouncedQuery] = useState("");
  const [variants, setVariants] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedQuery(query.trim()), 300);
    return () => clearTimeout(timer);
  }, [query]);

  const loadVariants = useCallback(async () => {
    if (debouncedQuery.length < 2) {
      setVariants([]);
      return;
    }

    setLoading(true);

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const path = `/api/v1/catalog?q=${encodeURIComponent(debouncedQuery)}`;
      const result = await fetchCatalog(path, { shop, sessionToken });

      if (result.ok) {
        setVariants(result.data?.variants ?? []);
      } else {
        setVariants([]);
      }
    } catch {
      setVariants([]);
    } finally {
      setLoading(false);
    }
  }, [debouncedQuery, shop, embedded]);

  useEffect(() => {
    loadVariants();
  }, [loadVariants]);

  return (
    <BlockStack gap="200">
      <TextField
        label="Search catalog"
        value={query}
        onChange={setQuery}
        placeholder="Search by SKU, product, or barcode…"
        autoComplete="off"
        disabled={disabled}
        loading={loading}
      />

      {variants.length > 0 ? (
        <div className={styles.searchResults} role="listbox">
          {variants.map((variant) => (
            <button
              key={variant.id}
              type="button"
              className={styles.searchResultButton}
              disabled={disabled}
              onClick={() => onSelect(variant)}
            >
              {variantLabel(variant)}
            </button>
          ))}
        </div>
      ) : debouncedQuery.length >= 2 && !loading ? (
        <Text as="p" variant="bodySm" tone="subdued">
          No matching variants.
        </Text>
      ) : null}
    </BlockStack>
  );
}
