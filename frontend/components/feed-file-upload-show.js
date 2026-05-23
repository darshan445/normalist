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
  DropZone,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { feedIcon, feedTypeLabel } from "../lib/feed-helpers";
import {
  fetchFeed,
  fetchFeedUploads,
  fetchUploadStatus,
  uploadFeedFile,
} from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import FeedColumnProfileCard from "./feed-column-profile-card";
import FeedUploadProcessing from "./feed-upload-processing";
import FeedUploadHistory from "./feed-upload-history";
import styles from "./supplier-detail.module.css";

const ACCEPTED_TYPES = [
  "text/csv",
  "application/vnd.ms-excel",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
];
const ACCEPTED_EXTENSIONS = [".csv", ".xlsx"];
const POLL_STATUSES = new Set(["pending", "processing"]);
const POLL_MS = 2000;

function FeedStatusBadge({ status }) {
  if (status === "active") return <Badge tone="success">active</Badge>;
  if (status === "paused") return <Badge>paused</Badge>;
  if (status === "error") return <Badge tone="critical">error</Badge>;
  return <Badge>{status}</Badge>;
}

function isAcceptedFile(file) {
  const name = file.name?.toLowerCase() ?? "";
  return ACCEPTED_EXTENSIONS.some((ext) => name.endsWith(ext));
}

export default function FeedFileUploadShow({ supplierId, feedId }) {
  const searchParams = useSearchParams();
  const { shop } = pickShopifyParams(searchParams);
  const shopifyParams = pickShopifyParams(searchParams);

  const [data, setData] = useState(null);
  const [history, setHistory] = useState([]);
  const [historyLoading, setHistoryLoading] = useState(true);
  const [loadState, setLoadState] = useState({ status: "loading", error: null });
  const [files, setFiles] = useState([]);
  const [fileError, setFileError] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [activeUpload, setActiveUpload] = useState(null);

  const supplierHref = shopifyNavHref(`/suppliers/${supplierId}`, shopifyParams);
  const reviewPendingHref = shopifyNavHref(
    `/review?supplier_id=${supplierId}`,
    shopifyParams
  );

  const loadHistory = useCallback(async () => {
    setHistoryLoading(true);
    try {
      const sessionToken = await fetchSessionToken();
      const result = await fetchFeedUploads(supplierId, feedId, { shop, sessionToken });
      if (result.ok) {
        setHistory(result.data?.uploads ?? []);
      }
    } catch {
      setHistory([]);
    } finally {
      setHistoryLoading(false);
    }
  }, [supplierId, feedId, shop]);

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
      setLoadState({ status: "ready", error: null });

      const latest = result.data.feed?.latest_upload;
      if (latest && POLL_STATUSES.has(latest.status)) {
        setActiveUpload(latest);
      }
    } catch (error) {
      setLoadState({ status: "error", error: error.message });
    }
  }, [supplierId, feedId, shop]);

  useEffect(() => {
    loadFeed();
    loadHistory();
  }, [loadFeed, loadHistory]);

  const pollUploadId = activeUpload?.id;
  const shouldPoll = activeUpload && POLL_STATUSES.has(activeUpload.status);

  useEffect(() => {
    if (!shouldPoll || !pollUploadId) return undefined;

    const poll = async () => {
      try {
        const sessionToken = await fetchSessionToken();
        const result = await fetchUploadStatus(supplierId, pollUploadId, {
          shop,
          sessionToken,
        });
        if (!result.ok) return;

        const upload = result.data?.upload;
        setActiveUpload(upload);

        if (upload && !POLL_STATUSES.has(upload.status)) {
          await loadFeed();
          await loadHistory();
        }
      } catch {
        /* keep polling */
      }
    };

    poll();
    const interval = setInterval(poll, POLL_MS);
    return () => clearInterval(interval);
  }, [shouldPoll, pollUploadId, supplierId, shop, loadFeed, loadHistory]);

  const handleDrop = useCallback((_dropFiles, acceptedFiles, rejectedFiles) => {
    setFileError(null);

    if (rejectedFiles.length > 0) {
      setFileError("Only .csv and .xlsx files are accepted.");
      setFiles([]);
      return;
    }

    const file = acceptedFiles[0];
    if (!file) {
      setFiles([]);
      return;
    }

    if (!isAcceptedFile(file)) {
      setFileError("Only .csv and .xlsx files are accepted.");
      setFiles([]);
      return;
    }

    setFiles([file]);
  }, []);

  const handleUpload = useCallback(async () => {
    if (files.length === 0) {
      setFileError("Please select a stock file to upload.");
      return;
    }

    setSubmitting(true);
    setFileError(null);

    try {
      const sessionToken = await fetchSessionToken();
      const result = await uploadFeedFile(supplierId, feedId, files[0], {
        shop,
        sessionToken,
      });

      if (!result.ok) {
        throw new Error(result.data?.errors?.join(", ") || "Could not upload file.");
      }

      setFiles([]);
      const upload = result.data?.upload;
      if (upload) {
        setActiveUpload(upload);
      }
      if (result.data?.supplier_profile) {
        setData((prev) =>
          prev ? { ...prev, supplier_profile: result.data.supplier_profile } : prev
        );
      }
      await loadHistory();
    } catch (err) {
      setFileError(err.message);
    } finally {
      setSubmitting(false);
    }
  }, [files, supplierId, feedId, shop, loadHistory]);

  const handleTryAgain = useCallback(() => {
    setActiveUpload(null);
    setFileError(null);
  }, []);

  const uploadBusy =
    submitting || (activeUpload && POLL_STATUSES.has(activeUpload.status));

  if (loadState.status === "loading" && !data) {
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

  if (loadState.status === "error" && !data) {
    return (
      <Banner tone="critical" title="Could not load feed">
        <p>{loadState.error}</p>
      </Banner>
    );
  }

  const { supplier, feed, supplier_profile: supplierProfile } = data;

  return (
    <BlockStack gap="500">
      <BlockStack gap="200">
        <Link href={supplierHref} className={styles.backLink}>
          ← {supplier.name}
        </Link>
        <InlineStack gap="200" blockAlign="center" wrap>
          <span className={styles.feedIcon} aria-hidden>
            {feedIcon(feed.feed_type)}
          </span>
          <BlockStack gap="100">
            <InlineStack gap="200" blockAlign="center">
              <Text as="h1" variant="headingLg">
                {feed.name}
              </Text>
              <FeedStatusBadge status={feed.status} />
            </InlineStack>
            <Text as="p" variant="bodySm" tone="subdued">
              {feedTypeLabel(feed.feed_type)}
            </Text>
          </BlockStack>
        </InlineStack>
      </BlockStack>

      <FeedColumnProfileCard profile={supplierProfile} />

      <Card>
        <BlockStack gap="400">
          <Text as="h2" variant="headingMd">
            Upload new file
          </Text>

          {fileError ? (
            <Banner tone="critical" onDismiss={() => setFileError(null)}>
              <p>{fileError}</p>
            </Banner>
          ) : null}

          <DropZone
            accept={ACCEPTED_TYPES.join(",")}
            type="file"
            onDrop={handleDrop}
            disabled={uploadBusy}
          >
            <DropZone.FileUpload actionHint="Accepts .csv and .xlsx only" />
          </DropZone>

          {files[0] ? (
            <Text as="p" variant="bodyMd">
              Selected: <strong>{files[0].name}</strong>
            </Text>
          ) : null}

          <div>
            <Button
              variant="primary"
              onClick={handleUpload}
              loading={submitting}
              disabled={files.length === 0 || uploadBusy}
            >
              Upload file
            </Button>
          </div>
        </BlockStack>
      </Card>

      {activeUpload ? (
        <FeedUploadProcessing
          upload={activeUpload}
          reviewPendingHref={reviewPendingHref}
          onTryAgain={handleTryAgain}
        />
      ) : null}

      <FeedUploadHistory
        uploads={history}
        loading={historyLoading}
        reviewPendingHref={reviewPendingHref}
      />
    </BlockStack>
  );
}
