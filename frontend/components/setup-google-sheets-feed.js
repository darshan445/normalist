"use client";

import { useCallback, useEffect, useRef, useState } from "react";
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
  Select,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import {
  createFeed,
  fetchGoogleSheetTabs,
  fetchSupplier,
  previewGoogleSheet,
} from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import GoogleSheetsPreviewPanel from "./google-sheets-preview-panel";
import styles from "./supplier-detail.module.css";

const URL_DEBOUNCE_MS = 600;

function googleSheetsErrorMessage(result) {
  return result.data?.message || result.data?.error || "Request failed.";
}

export default function SetupGoogleSheetsFeed({ supplierId }) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { shop, embedded } = pickShopifyParams(searchParams);
  const shopifyParams = pickShopifyParams(searchParams);

  const [supplierName, setSupplierName] = useState("");
  const [loadingSupplier, setLoadingSupplier] = useState(true);
  const [url, setUrl] = useState("");
  const [tabs, setTabs] = useState([]);
  const [selectedTabGid, setSelectedTabGid] = useState("");
  const [preview, setPreview] = useState(null);
  const [loadingTabs, setLoadingTabs] = useState(false);
  const [loadingPreview, setLoadingPreview] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);

  const urlDebounceRef = useRef(null);

  const supplierHref = shopifyNavHref(`/suppliers/${supplierId}`, shopifyParams);
  const selectedTab = tabs.find((tab) => tab.gid === selectedTabGid);

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

  const loadPreview = useCallback(
    async (sheetUrl, tabGid) => {
      if (!sheetUrl.trim() || !tabGid) return;

      setLoadingPreview(true);
      setPreview(null);
      setError(null);

      try {
        const sessionToken = embedded ? await fetchSessionToken() : null;
        const result = await previewGoogleSheet(
          { url: sheetUrl.trim(), tab_gid: tabGid, supplier_id: supplierId },
          { shop, sessionToken }
        );

        if (!result.ok) {
          throw new Error(googleSheetsErrorMessage(result));
        }

        setPreview(result.data);
      } catch (err) {
        setError(err.message || "Could not preview sheet.");
      } finally {
        setLoadingPreview(false);
      }
    },
    [supplierId, shop, embedded]
  );

  const loadTabsForUrl = useCallback(
    async (sheetUrl) => {
      if (!sheetUrl.trim()) return;

      setLoadingTabs(true);
      setError(null);
      setTabs([]);
      setSelectedTabGid("");
      setPreview(null);

      try {
        const sessionToken = embedded ? await fetchSessionToken() : null;
        const result = await fetchGoogleSheetTabs(sheetUrl.trim(), { shop, sessionToken });

        if (!result.ok) {
          throw new Error(googleSheetsErrorMessage(result));
        }

        const nextTabs = result.data?.tabs ?? [];
        if (nextTabs.length === 0) {
          throw new Error("No tabs found in this spreadsheet.");
        }

        setTabs(nextTabs);
      } catch (err) {
        setError(err.message || "Could not load sheet tabs.");
      } finally {
        setLoadingTabs(false);
      }
    },
    [shop, embedded]
  );

  useEffect(() => {
    if (urlDebounceRef.current) {
      clearTimeout(urlDebounceRef.current);
    }

    if (!url.trim()) {
      setTabs([]);
      setSelectedTabGid("");
      setPreview(null);
      return undefined;
    }

    urlDebounceRef.current = setTimeout(() => {
      loadTabsForUrl(url.trim());
    }, URL_DEBOUNCE_MS);

    return () => {
      if (urlDebounceRef.current) {
        clearTimeout(urlDebounceRef.current);
      }
    };
  }, [url, loadTabsForUrl]);

  const handleTabChange = useCallback(
    async (value) => {
      setSelectedTabGid(value);
      setPreview(null);
      setError(null);

      if (!value) return;

      await loadPreview(url.trim(), value);
    },
    [url, loadPreview]
  );

  const handleSubmit = useCallback(async () => {
    if (!url.trim()) {
      setError("Google Sheets URL is required.");
      return;
    }

    if (!selectedTabGid) {
      setError("Select a sheet tab.");
      return;
    }

    if (!preview) {
      setError("Select a sheet tab to detect columns before creating the feed.");
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await createFeed(
        supplierId,
        {
          feed_type: "google_sheets",
          url: url.trim(),
          tab_gid: selectedTabGid,
          tab_name: selectedTab?.name || "",
        },
        { shop, sessionToken }
      );

      if (!result.ok) {
        const message =
          result.data?.message ||
          result.data?.errors?.join(", ") ||
          "Could not create feed.";
        throw new Error(message);
      }

      const feedId = result.data.feed.id;
      router.push(shopifyNavHref(`/suppliers/${supplierId}/feeds/${feedId}`, shopifyParams));
    } catch (err) {
      setError(err.message || "Could not create feed.");
      setSubmitting(false);
    }
  }, [
    url,
    selectedTabGid,
    selectedTab,
    preview,
    supplierId,
    shop,
    embedded,
    router,
    shopifyParams,
  ]);

  if (loadingSupplier) {
    return (
      <BlockStack gap="300" inlineAlign="center">
        <Spinner accessibilityLabel="Loading" />
      </BlockStack>
    );
  }

  const tabOptions = [
    { label: "Select a sheet tab", value: "" },
    ...tabs.map((tab) => ({
      label: tab.name,
      value: tab.gid,
    })),
  ];

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
          Paste a published Google Sheets URL, choose a tab, then we detect columns from that tab.
        </Text>
      </BlockStack>

      {error ? (
        <Banner tone="critical" onDismiss={() => setError(null)}>
          <p>{error}</p>
        </Banner>
      ) : null}

      <Card>
        <BlockStack gap="400">
          <TextField
            label="Google Sheets URL"
            value={url}
            onChange={setUrl}
            autoComplete="off"
            placeholder="https://docs.google.com/spreadsheets/d/..."
            disabled={submitting || loadingTabs}
            helpText={
              loadingTabs
                ? "Loading sheet tabs…"
                : "Sheet tabs load automatically when you paste a URL."
            }
          />

          {tabs.length > 0 ? (
            <Select
              label="Sheet tab"
              options={tabOptions}
              value={selectedTabGid}
              onChange={handleTabChange}
              disabled={submitting || loadingPreview || loadingTabs}
              helpText="Column detection runs after you choose a tab."
            />
          ) : null}
        </BlockStack>
      </Card>

      <GoogleSheetsPreviewPanel
        preview={preview}
        loading={loadingPreview}
        error={null}
        tabSelected={Boolean(selectedTabGid)}
      />

      <BlockStack gap="200">
        <Button
          variant="primary"
          onClick={handleSubmit}
          loading={submitting}
          disabled={!preview || loadingPreview || loadingTabs}
        >
          Create feed
        </Button>
        <Button url={supplierHref} disabled={submitting}>
          Cancel
        </Button>
      </BlockStack>
    </BlockStack>
  );
}
