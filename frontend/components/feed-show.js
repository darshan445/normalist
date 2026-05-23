"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Button,
  Badge,
  Banner,
  Spinner,
  TextField,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { feedIcon, feedTypeLabel } from "../lib/feed-helpers";
import { fetchFeed, updateFeed } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import FeedFileUploadShow from "./feed-file-upload-show";
import styles from "./supplier-detail.module.css";

function FeedStatusBadge({ status }) {
  if (status === "active") return <Badge tone="success">active</Badge>;
  if (status === "error") return <Badge tone="critical">error</Badge>;
  return <Badge>{status}</Badge>;
}

function GoogleSheetsFeedShow({ supplierId, feedId }) {
  const searchParams = useSearchParams();
  const { shop } = pickShopifyParams(searchParams);
  const shopifyParams = pickShopifyParams(searchParams);

  const [data, setData] = useState(null);
  const [loadState, setLoadState] = useState({ status: "loading", error: null });
  const [url, setUrl] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState(null);
  const [successMessage, setSuccessMessage] = useState(null);

  const loadFeed = useCallback(async () => {
    try {
      const sessionToken = await fetchSessionToken();
      const result = await fetchFeed(supplierId, feedId, { shop, sessionToken });

      if (result.status === 404) {
        setLoadState({ status: "not_found", error: null });
        return;
      }

      if (!result.ok) {
        setLoadState({
          status: "error",
          error: result.data?.message || "Could not load feed.",
        });
        return;
      }

      setData(result.data);
      setUrl(result.data.feed.url || "");
      setLoadState({ status: "ready", error: null });
    } catch (error) {
      setLoadState({ status: "error", error: error.message });
    }
  }, [supplierId, feedId, shop]);

  useEffect(() => {
    loadFeed();
  }, [loadFeed]);

  const supplierHref = shopifyNavHref(`/suppliers/${supplierId}`, shopifyParams);

  const handleSaveGoogleSheets = useCallback(async () => {
    if (!url.trim()) {
      setFormError("Google Sheets URL is required.");
      return;
    }

    setSubmitting(true);
    setFormError(null);
    setSuccessMessage(null);

    try {
      const sessionToken = await fetchSessionToken();
      const result = await updateFeed(
        supplierId,
        feedId,
        { url: url.trim() },
        { shop, sessionToken }
      );

      if (!result.ok) {
        throw new Error(
          result.data?.errors?.join(", ") || "Could not save Google Sheets URL."
        );
      }

      setData(result.data);
      setSuccessMessage("Google Sheets URL saved.");
    } catch (err) {
      setFormError(err.message);
    } finally {
      setSubmitting(false);
    }
  }, [url, supplierId, feedId, shop]);

  if (loadState.status === "loading") {
    return (
      <BlockStack gap="300" inlineAlign="center">
        <Spinner accessibilityLabel="Loading feed" />
      </BlockStack>
    );
  }

  if (loadState.status === "not_found") {
    return (
      <Banner tone="warning">
        <p>
          <Link href={supplierHref}>Back to supplier</Link>
        </p>
      </Banner>
    );
  }

  if (loadState.status === "error" || !data?.feed) {
    return (
      <Banner tone="critical">
        <p>{loadState.error || "Could not load feed."}</p>
      </Banner>
    );
  }

  const { supplier, feed } = data;

  return (
    <BlockStack gap="500">
      <Link href={supplierHref} className={styles.backLink}>
        ← {supplier.name}
      </Link>
      <InlineStack gap="200" blockAlign="center">
        <span className={styles.feedIcon} aria-hidden>
          {feedIcon(feed.feed_type)}
        </span>
        <BlockStack gap="100">
          <Text as="h1" variant="headingLg">
            {feed.name}
          </Text>
          <Text as="p" variant="bodySm" tone="subdued">
            {feedTypeLabel(feed.feed_type)}
          </Text>
        </BlockStack>
        <FeedStatusBadge status={feed.status} />
      </InlineStack>

      {formError ? (
        <Banner tone="critical" onDismiss={() => setFormError(null)}>
          <p>{formError}</p>
        </Banner>
      ) : null}
      {successMessage ? (
        <Banner tone="success" onDismiss={() => setSuccessMessage(null)}>
          <p>{successMessage}</p>
        </Banner>
      ) : null}

      <Card>
        <BlockStack gap="300">
          <TextField
            label="Google Sheets URL"
            value={url}
            onChange={setUrl}
            autoComplete="off"
            placeholder="https://docs.google.com/spreadsheets/d/..."
            disabled={submitting}
          />
          <Button variant="primary" onClick={handleSaveGoogleSheets} loading={submitting}>
            Save URL
          </Button>
        </BlockStack>
      </Card>
    </BlockStack>
  );
}

export default function FeedShow({ supplierId, feedId }) {
  const [feedType, setFeedType] = useState(null);
  const searchParams = useSearchParams();
  const { shop } = pickShopifyParams(searchParams);

  useEffect(() => {
    let cancelled = false;

    async function detectType() {
      const sessionToken = await fetchSessionToken();
      const result = await fetchFeed(supplierId, feedId, { shop, sessionToken });
      if (!cancelled && result.ok) {
        setFeedType(result.data?.feed?.feed_type ?? null);
      } else if (!cancelled) {
        setFeedType("unknown");
      }
    }

    detectType();
    return () => {
      cancelled = true;
    };
  }, [supplierId, feedId, shop]);

  if (!feedType) {
    return (
      <BlockStack gap="300" inlineAlign="center">
        <Spinner accessibilityLabel="Loading feed" />
      </BlockStack>
    );
  }

  if (feedType === "file_upload") {
    return <FeedFileUploadShow supplierId={supplierId} feedId={feedId} />;
  }

  return <GoogleSheetsFeedShow supplierId={supplierId} feedId={feedId} />;
}
