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
  DropZone,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { feedIcon, feedTypeLabel } from "../lib/feed-helpers";
import { fetchFeed, updateFeed, uploadFeedFile } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import { formatRelativeTime } from "../lib/format-relative-time";
import styles from "./supplier-detail.module.css";

function FeedStatusBadge({ status }) {
  if (status === "active") return <Badge tone="success">active</Badge>;
  if (status === "error") return <Badge tone="critical">error</Badge>;
  return <Badge>{status}</Badge>;
}

function UploadStatusBadge({ status }) {
  if (status === "completed") return <Badge tone="success">completed</Badge>;
  if (status === "failed") return <Badge tone="critical">failed</Badge>;
  if (status === "processing" || status === "pending") {
    return <Badge tone="info">processing</Badge>;
  }
  return <Badge>{status}</Badge>;
}

const POLL_STATUSES = new Set(["pending", "processing"]);

export default function FeedShow({ supplierId, feedId }) {
  const searchParams = useSearchParams();
  const { shop } = pickShopifyParams(searchParams);
  const shopifyParams = pickShopifyParams(searchParams);

  const [data, setData] = useState(null);
  const [loadState, setLoadState] = useState({ status: "loading", error: null });
  const [url, setUrl] = useState("");
  const [files, setFiles] = useState([]);
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

      const upload = result.data.feed?.latest_upload;
      if (upload?.status === "failed") {
        setSuccessMessage(null);
        setFormError(upload.error_message || "Upload failed.");
      } else if (upload?.status === "completed" || upload?.status === "needs_review") {
        setSuccessMessage(null);
        setFormError(null);
      }
    } catch (error) {
      setLoadState({ status: "error", error: error.message });
    }
  }, [supplierId, feedId, shop]);

  useEffect(() => {
    loadFeed();
  }, [loadFeed]);

  const uploadStatus = data?.feed?.latest_upload?.status;
  const shouldPoll = uploadStatus && POLL_STATUSES.has(uploadStatus);

  useEffect(() => {
    if (!shouldPoll) return undefined;

    const interval = setInterval(() => {
      loadFeed();
    }, 2000);

    return () => clearInterval(interval);
  }, [shouldPoll, loadFeed]);

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

  const handleUploadFile = useCallback(async () => {
    if (files.length === 0) {
      setFormError("Please select a stock file to upload.");
      return;
    }

    setSubmitting(true);
    setFormError(null);
    setSuccessMessage(null);

    try {
      const sessionToken = await fetchSessionToken();
      const result = await uploadFeedFile(
        supplierId,
        feedId,
        files[0],
        { shop, sessionToken }
      );

      if (!result.ok) {
        throw new Error(result.data?.errors?.join(", ") || "Could not upload file.");
      }

      setFiles([]);
      setSuccessMessage("File uploaded — processing file…");
      await loadFeed();
    } catch (err) {
      setFormError(err.message);
    } finally {
      setSubmitting(false);
    }
  }, [files, supplierId, feedId, shop, loadFeed]);

  if (loadState.status === "loading") {
    return (
      <BlockStack gap="300" inlineAlign="center">
        <Spinner accessibilityLabel="Loading feed" />
        <Text as="p" variant="bodyMd" tone="subdued">
          Loading feed…
        </Text>
      </BlockStack>
    );
  }

  if (loadState.status === "not_found") {
    return (
      <Banner tone="warning">
        <p>This feed does not exist or you do not have access to it.</p>
        <p>
          <Link href={supplierHref}>Back to supplier</Link>
        </p>
      </Banner>
    );
  }

  if (loadState.status === "error") {
    return (
      <Banner tone="critical" title="Could not load feed">
        <p>{loadState.error}</p>
      </Banner>
    );
  }

  if (!data?.supplier || !data?.feed) {
    return (
      <BlockStack gap="300" inlineAlign="center">
        <Spinner accessibilityLabel="Loading feed" />
        <Text as="p" variant="bodyMd" tone="subdued">
          Loading feed…
        </Text>
      </BlockStack>
    );
  }

  const { supplier, feed } = data;
  const latestUpload = feed.latest_upload;
  const selectedFile = files[0];
  const uploadProcessing =
    latestUpload?.status === "processing" || latestUpload?.status === "pending";

  return (
    <BlockStack gap="500">
      <BlockStack gap="200">
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
        </InlineStack>
      </BlockStack>

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

      {uploadProcessing ? (
        <Banner tone="info">
          <InlineStack gap="200" blockAlign="center">
            <Spinner size="small" accessibilityLabel="Processing" />
            <p>{latestUpload.stage || "Processing upload…"}</p>
          </InlineStack>
        </Banner>
      ) : null}

      <Card>
        <BlockStack gap="400">
          <InlineStack align="space-between" blockAlign="center">
            <Text as="span" variant="bodyMd" tone="subdued">
              Status
            </Text>
            <FeedStatusBadge status={feed.status} />
          </InlineStack>

          {feed.feed_type === "google_sheets" ? (
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
          ) : null}

          {feed.feed_type === "file_upload" ? (
            <BlockStack gap="300">
              <Text as="p" variant="bodyMd" tone="subdued">
                Upload a CSV or Excel stock file for this feed.
              </Text>
              <DropZone
                accept=".csv,.xlsx,text/csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                type="file"
                onDrop={setFiles}
                disabled={submitting || uploadProcessing}
              >
                <DropZone.FileUpload actionHint="Accepts .csv and .xlsx" />
              </DropZone>
              {selectedFile ? (
                <Text as="p" variant="bodyMd">
                  Selected: <strong>{selectedFile.name}</strong>
                </Text>
              ) : null}
              <Button
                variant="primary"
                onClick={handleUploadFile}
                loading={submitting}
                disabled={files.length === 0 || uploadProcessing}
              >
                Upload file
              </Button>
            </BlockStack>
          ) : null}

          {latestUpload ? (
            <BlockStack gap="200">
              <Text as="p" variant="headingSm">
                Last upload
              </Text>
              <InlineStack align="space-between" blockAlign="center">
                <Text as="span" variant="bodyMd" tone="subdued">
                  Status
                </Text>
                <UploadStatusBadge status={latestUpload.status} />
              </InlineStack>
              <InlineStack align="space-between" blockAlign="center">
                <Text as="span" variant="bodyMd" tone="subdued">
                  Uploaded
                </Text>
                <Text as="span" variant="bodyMd">
                  {formatRelativeTime(latestUpload.created_at)}
                </Text>
              </InlineStack>
              {latestUpload.stage ? (
                <InlineStack align="space-between" blockAlign="center">
                  <Text as="span" variant="bodyMd" tone="subdued">
                    Stage
                  </Text>
                  <Text as="span" variant="bodyMd">
                    {latestUpload.stage}
                  </Text>
                </InlineStack>
              ) : null}
              {latestUpload.status === "completed" ? (
                <>
                  <InlineStack align="space-between" blockAlign="center">
                    <Text as="span" variant="bodyMd" tone="subdued">
                      Resolved
                    </Text>
                    <Text as="span" variant="bodyMd">
                      {latestUpload.resolved_count ?? 0}
                    </Text>
                  </InlineStack>
                  <InlineStack align="space-between" blockAlign="center">
                    <Text as="span" variant="bodyMd" tone="subdued">
                      Need attention
                    </Text>
                    <Text as="span" variant="bodyMd">
                      {latestUpload.unresolved_count ?? 0}
                    </Text>
                  </InlineStack>
                  {(latestUpload.unmatched_count ?? 0) > 0 ? (
                    <InlineStack align="space-between" blockAlign="center">
                      <Text as="span" variant="bodyMd" tone="subdued">
                        Unmatched (Phase 3)
                      </Text>
                      <Text as="span" variant="bodyMd">
                        {latestUpload.unmatched_count}
                      </Text>
                    </InlineStack>
                  ) : null}
                </>
              ) : null}
              {latestUpload.error_message ? (
                <Banner tone="critical">
                  <p>{latestUpload.error_message}</p>
                </Banner>
              ) : null}
            </BlockStack>
          ) : null}
        </BlockStack>
      </Card>
    </BlockStack>
  );
}
