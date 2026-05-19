"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  Button,
  DropZone,
  Banner,
  Spinner,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { createFeedWithFile } from "../lib/api";
import { fetchSupplier } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import styles from "./supplier-detail.module.css";

export default function SetupFileUploadFeed({ supplierId }) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { shop, embedded } = pickShopifyParams(searchParams);
  const shopifyParams = pickShopifyParams(searchParams);

  const [supplierName, setSupplierName] = useState("");
  const [loadingSupplier, setLoadingSupplier] = useState(true);
  const [files, setFiles] = useState([]);
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
          const hasFileUpload = (result.data.feeds ?? []).some(
            (f) => f.feed_type === "file_upload"
          );
          if (hasFileUpload) {
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
    if (files.length === 0) {
      setError("Please select a stock file to upload.");
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await createFeedWithFile(
        supplierId,
        { feed_type: "file_upload", file: files[0] },
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
  }, [files, supplierId, shop, embedded, router, shopifyParams]);

  if (loadingSupplier) {
    return (
      <BlockStack gap="300" inlineAlign="center">
        <Spinner accessibilityLabel="Loading" />
      </BlockStack>
    );
  }

  const file = files[0];

  return (
    <BlockStack gap="500">
      <BlockStack gap="200">
        <Link href={supplierHref} className={styles.backLink}>
          ← {supplierName || "Supplier"}
        </Link>
        <Text as="h1" variant="headingLg">
          File Upload feed
        </Text>
        <Text as="p" variant="bodySm" tone="subdued">
          Upload a CSV or Excel stock file. This is required to create the feed.
        </Text>
      </BlockStack>

      <Card>
        <BlockStack gap="400">
          {error ? (
            <Banner tone="critical" onDismiss={() => setError(null)}>
              <p>{error}</p>
            </Banner>
          ) : null}

          <DropZone
            accept=".csv,.xlsx,text/csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            type="file"
            onDrop={setFiles}
            disabled={submitting}
          >
            <DropZone.FileUpload actionHint="Accepts .csv and .xlsx" />
          </DropZone>

          {file ? (
            <Text as="p" variant="bodyMd">
              Selected: <strong>{file.name}</strong>
            </Text>
          ) : null}

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
