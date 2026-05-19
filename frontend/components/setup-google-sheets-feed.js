"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  Button,
  TextField,
  Banner,
  Spinner,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { createFeed } from "../lib/api";
import { fetchSupplier } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import styles from "./supplier-detail.module.css";

export default function SetupGoogleSheetsFeed({ supplierId }) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { shop, embedded } = pickShopifyParams(searchParams);
  const shopifyParams = pickShopifyParams(searchParams);

  const [supplierName, setSupplierName] = useState("");
  const [loadingSupplier, setLoadingSupplier] = useState(true);
  const [url, setUrl] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);

  const supplierHref = shopifyNavHref(`/suppliers/${supplierId}`, shopifyParams);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        const sessionToken = embedded ? await fetchSessionToken() : null;
        const result = await fetchSupplier(supplierId, { shop, sessionToken });
        if (!cancelled && result.ok) {
          const hasGoogleSheets = (result.data.feeds ?? []).some(
            (f) => f.feed_type === "google_sheets"
          );
          if (hasGoogleSheets) {
            router.replace(supplierHref);
            return;
          }
          setSupplierName(result.data.supplier.name);
        }
      } finally {
        if (!cancelled) setLoadingSupplier(false);
      }
    }

    load();
    return () => {
      cancelled = true;
    };
  }, [supplierId, shop, embedded, router, supplierHref]);

  const handleSubmit = useCallback(async () => {
    if (!url.trim()) {
      setError("Google Sheets URL is required.");
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await createFeed(
        supplierId,
        { feed_type: "google_sheets", url: url.trim() },
        { shop, sessionToken }
      );

      if (!result.ok) {
        const message =
          result.data?.errors?.join(", ") ||
          result.data?.message ||
          "Could not create feed.";
        throw new Error(message);
      }

      const feedId = result.data.feed.id;
      router.push(shopifyNavHref(`/suppliers/${supplierId}/feeds/${feedId}`, shopifyParams));
    } catch (err) {
      setError(err.message || "Could not create feed.");
      setSubmitting(false);
    }
  }, [url, supplierId, shop, embedded, router, shopifyParams]);

  if (loadingSupplier) {
    return (
      <BlockStack gap="300" inlineAlign="center">
        <Spinner accessibilityLabel="Loading" />
      </BlockStack>
    );
  }

  return (
    <BlockStack gap="500">
      <BlockStack gap="200">
        <Link href={supplierHref} className={styles.backLink}>
          ← {supplierName || "Supplier"}
        </Link>
        <Text as="h1" variant="headingLg">
          Google Sheets feed
        </Text>
        <Text as="p" variant="bodySm" tone="subdued">
          Paste the URL of your published Google Sheet.
        </Text>
      </BlockStack>

      <Card>
        <BlockStack gap="400">
          {error ? (
            <Banner tone="critical" onDismiss={() => setError(null)}>
              <p>{error}</p>
            </Banner>
          ) : null}

          <TextField
            label="Google Sheets URL"
            value={url}
            onChange={setUrl}
            autoComplete="off"
            placeholder="https://docs.google.com/spreadsheets/d/..."
            disabled={submitting}
          />

          <BlockStack gap="200">
            <Button variant="primary" onClick={handleSubmit} loading={submitting}>
              Create feed
            </Button>
            <Button url={supplierHref} disabled={submitting}>
              Cancel
            </Button>
          </BlockStack>
        </BlockStack>
      </Card>
    </BlockStack>
  );
}
