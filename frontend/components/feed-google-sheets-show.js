"use client";

import { useCallback, useEffect, useRef, useState } from "react";
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
  Select,
  ChoiceList,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import {
  feedIcon,
  feedTypeLabel,
  syncIntervalLabel,
  SYNC_INTERVAL_OPTIONS,
  DEFAULT_SYNC_INTERVAL,
} from "../lib/feed-helpers";
import {
  fetchFeed,
  fetchFeedSyncs,
  fetchGoogleSheetTabs,
  fetchUploadStatus,
  previewGoogleSheet,
  triggerFeedSync,
  updateFeed,
} from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import FeedColumnProfileCard from "./feed-column-profile-card";
import GoogleSheetsPreviewPanel, {
  previewFromSupplierProfile,
} from "./google-sheets-preview-panel";
import FeedLastSync from "./feed-last-sync";
import FeedSyncHistory from "./feed-sync-history";
import styles from "./supplier-detail.module.css";

const POLL_STATUSES = new Set(["pending", "processing"]);
const POLL_MS = 2000;
const URL_DEBOUNCE_MS = 600;

function googleSheetsErrorMessage(result) {
  return result.data?.message || result.data?.error || "Request failed.";
}

function FeedStatusBadge({ status }) {
  if (status === "active") return <Badge tone="success">active</Badge>;
  if (status === "error") return <Badge tone="critical">error</Badge>;
  return <Badge>{status}</Badge>;
}

export default function FeedGoogleSheetsShow({ supplierId, feedId }) {
  const searchParams = useSearchParams();
  const { shop } = pickShopifyParams(searchParams);
  const shopifyParams = pickShopifyParams(searchParams);

  const [data, setData] = useState(null);
  const [loadState, setLoadState] = useState({ status: "loading", error: null });
  const [url, setUrl] = useState("");
  const [tabs, setTabs] = useState([]);
  const [selectedTabGid, setSelectedTabGid] = useState("");
  const [syncInterval, setSyncInterval] = useState(DEFAULT_SYNC_INTERVAL);
  const [preview, setPreview] = useState(null);
  const [loadingTabs, setLoadingTabs] = useState(false);
  const [loadingPreview, setLoadingPreview] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [formError, setFormError] = useState(null);
  const [successMessage, setSuccessMessage] = useState(null);
  const [syncHistory, setSyncHistory] = useState([]);
  const [historyLoading, setHistoryLoading] = useState(true);
  const [activeUpload, setActiveUpload] = useState(null);

  const skipUrlReloadRef = useRef(true);
  const urlDebounceRef = useRef(null);
  const lastDetectedRef = useRef({ url: "", tabGid: "" });
  const initialLoadDoneRef = useRef(false);

  const selectedTab = tabs.find((tab) => tab.gid === selectedTabGid);

  const supplierHref = shopifyNavHref(`/suppliers/${supplierId}`, shopifyParams);
  const reviewPendingHref = shopifyNavHref(
    `/review?supplier_id=${supplierId}`,
    shopifyParams
  );

  const loadPreview = useCallback(
    async (sheetUrl, tabGid, { force = false } = {}) => {
      if (!sheetUrl.trim() || !tabGid) return;

      const normalizedUrl = sheetUrl.trim();
      if (
        !force &&
        lastDetectedRef.current.url === normalizedUrl &&
        lastDetectedRef.current.tabGid === tabGid
      ) {
        return;
      }

      setLoadingPreview(true);
      setPreview(null);

      try {
        const sessionToken = await fetchSessionToken();
        const result = await previewGoogleSheet(
          { url: normalizedUrl, tab_gid: tabGid, supplier_id: supplierId },
          { shop, sessionToken }
        );

        if (!result.ok) {
          throw new Error(googleSheetsErrorMessage(result));
        }

        lastDetectedRef.current = { url: normalizedUrl, tabGid };
        setPreview(result.data);
      } catch (error) {
        setFormError(error.message || "Could not preview sheet.");
      } finally {
        setLoadingPreview(false);
      }
    },
    [supplierId, shop]
  );

  const loadTabsForUrl = useCallback(
    async (sheetUrl, { preferredGid = "", runPreview = false } = {}) => {
      if (!sheetUrl.trim()) return;

      setLoadingTabs(true);
      setFormError(null);

      try {
        const sessionToken = await fetchSessionToken();
        const result = await fetchGoogleSheetTabs(sheetUrl.trim(), { shop, sessionToken });

        if (!result.ok) {
          throw new Error(googleSheetsErrorMessage(result));
        }

        const nextTabs = result.data?.tabs ?? [];
        if (nextTabs.length === 0) {
          throw new Error("No tabs found in this spreadsheet.");
        }

        setTabs(nextTabs);

        const matchedGid =
          preferredGid && nextTabs.some((tab) => tab.gid === preferredGid) ? preferredGid : "";

        setSelectedTabGid(matchedGid);
        if (!runPreview) {
          setPreview(null);
          lastDetectedRef.current = { url: "", tabGid: "" };
        }

        if (runPreview && matchedGid) {
          await loadPreview(sheetUrl.trim(), matchedGid);
        }
      } catch (err) {
        setFormError(err.message || "Could not load sheet tabs.");
        setTabs([]);
        setPreview(null);
        setSelectedTabGid("");
      } finally {
        setLoadingTabs(false);
      }
    },
    [shop, loadPreview]
  );

  const loadSyncHistory = useCallback(async () => {
    setHistoryLoading(true);
    try {
      const sessionToken = await fetchSessionToken();
      const result = await fetchFeedSyncs(feedId, { shop, sessionToken });
      if (result.ok) {
        setSyncHistory(result.data?.uploads ?? []);
      }
    } catch {
      setSyncHistory([]);
    } finally {
      setHistoryLoading(false);
    }
  }, [feedId, shop]);

  const refreshFeedData = useCallback(async () => {
    try {
      const sessionToken = await fetchSessionToken();
      const result = await fetchFeed(supplierId, feedId, { shop, sessionToken });
      if (!result.ok) return;

      setData(result.data);

      const latest = result.data.feed?.latest_upload;
      setActiveUpload(latest ?? null);
    } catch {
      /* ignore refresh errors */
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

      const feed = result.data.feed;
      setData(result.data);
      setUrl(feed.url || "");
      setSelectedTabGid(feed.tab_gid || "");
      setSyncInterval(feed.interval || DEFAULT_SYNC_INTERVAL);
      skipUrlReloadRef.current = true;

      if (feed.url && !initialLoadDoneRef.current) {
        await loadTabsForUrl(feed.url, {
          preferredGid: feed.tab_gid || "",
          runPreview: false,
        });
        initialLoadDoneRef.current = true;
      }

      const cachedPreview = previewFromSupplierProfile(result.data.supplier_profile);
      if (cachedPreview && feed.tab_gid) {
        setPreview(cachedPreview);
        lastDetectedRef.current = { url: feed.url || "", tabGid: feed.tab_gid };
      }

      setLoadState({ status: "ready", error: null });

      const latest = feed.latest_upload;
      if (latest && POLL_STATUSES.has(latest.status)) {
        setActiveUpload(latest);
      } else {
        setActiveUpload(latest ?? null);
      }
    } catch (error) {
      setLoadState({ status: "error", error: error.message });
    }
  }, [supplierId, feedId, shop, loadTabsForUrl]);

  useEffect(() => {
    loadFeed();
    loadSyncHistory();
  }, [loadFeed, loadSyncHistory]);

  useEffect(() => {
    if (loadState.status !== "ready") return undefined;
    if (skipUrlReloadRef.current) {
      skipUrlReloadRef.current = false;
      return undefined;
    }

    if (urlDebounceRef.current) {
      clearTimeout(urlDebounceRef.current);
    }

    if (!url.trim()) {
      setTabs([]);
      setSelectedTabGid("");
      setPreview(null);
      lastDetectedRef.current = { url: "", tabGid: "" };
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
  }, [url, loadState.status, loadTabsForUrl]);

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
          await refreshFeedData();
          await loadSyncHistory();
          setSyncing(false);
        }
      } catch {
        /* keep polling */
      }
    };

    poll();
    const intervalId = setInterval(poll, POLL_MS);
    return () => clearInterval(intervalId);
  }, [shouldPoll, pollUploadId, supplierId, shop, refreshFeedData, loadSyncHistory]);

  const handleTabChange = useCallback(
    async (value) => {
      if (value === selectedTabGid) return;

      setSelectedTabGid(value);
      setFormError(null);
      setPreview(null);
      lastDetectedRef.current = { url: "", tabGid: "" };

      if (!value) return;

      await loadPreview(url.trim(), value, { force: true });
    },
    [url, loadPreview, selectedTabGid]
  );

  const handleSaveGoogleSheets = useCallback(async () => {
    if (!url.trim()) {
      setFormError("Google Sheets URL is required.");
      return;
    }

    if (!selectedTabGid) {
      setFormError("Select a sheet tab.");
      return;
    }

    const savedFeed = data?.feed;
    const connectionChanged =
      url.trim() !== (savedFeed?.url || "") ||
      selectedTabGid !== (savedFeed?.tab_gid || "");

    if (connectionChanged && !preview) {
      setFormError("Select a sheet tab to detect columns before saving.");
      return;
    }

    if (connectionChanged && preview?.from_cache) {
      setFormError("Change the sheet tab to re-detect columns before saving.");
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
        {
          url: url.trim(),
          tab_gid: selectedTabGid,
          tab_name: selectedTab?.name || "",
          interval: syncInterval,
        },
        { shop, sessionToken }
      );

      if (!result.ok) {
        throw new Error(
          result.data?.message ||
            result.data?.errors?.join(", ") ||
            "Could not save Google Sheets feed."
        );
      }

      setData(result.data);
      skipUrlReloadRef.current = true;

      const savedPreview = previewFromSupplierProfile(result.data.supplier_profile);
      if (savedPreview) {
        setPreview(savedPreview);
        lastDetectedRef.current = { url: url.trim(), tabGid: selectedTabGid };
      }

      setSuccessMessage("Google Sheets feed saved and column profile updated.");
    } catch (err) {
      setFormError(err.message);
    } finally {
      setSubmitting(false);
    }
  }, [
    url,
    selectedTabGid,
    selectedTab,
    syncInterval,
    data,
    preview,
    supplierId,
    feedId,
    shop,
  ]);

  const handleSyncNow = useCallback(async () => {
    setSyncing(true);
    setFormError(null);

    const previousUploadId = data?.feed?.latest_upload?.id ?? null;

    try {
      const sessionToken = await fetchSessionToken();
      const result = await triggerFeedSync(feedId, { shop, sessionToken });

      if (!result.ok) {
        throw new Error(
          result.data?.message ||
            result.data?.errors?.join(", ") ||
            "Could not start sync."
        );
      }

      for (let attempt = 0; attempt < 20; attempt += 1) {
        await new Promise((resolve) => {
          setTimeout(resolve, 1000);
        });

        const feedResult = await fetchFeed(supplierId, feedId, { shop, sessionToken });
        if (!feedResult.ok) continue;

        const latest = feedResult.data?.feed?.latest_upload;
        if (latest && latest.id !== previousUploadId) {
          setData(feedResult.data);
          setActiveUpload(latest);
          await loadSyncHistory();
          if (!POLL_STATUSES.has(latest.status)) {
            setSyncing(false);
          }
          return;
        }
      }

      await refreshFeedData();
      await loadSyncHistory();
      setSyncing(false);
    } catch (err) {
      setFormError(err.message);
      setSyncing(false);
    }
  }, [data, feedId, supplierId, shop, refreshFeedData, loadSyncHistory]);

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

  if (loadState.status === "error" && !data?.feed) {
    return (
      <Banner tone="critical" title="Could not load feed">
        <p>{loadState.error || "Could not load feed."}</p>
      </Banner>
    );
  }

  const { supplier, feed, supplier_profile: supplierProfile } = data;
  const tabOptions = [
    { label: "Select a sheet tab", value: "" },
    ...tabs.map((tab) => ({
      label: tab.name,
      value: tab.gid,
    })),
  ];
  const displayTabName = selectedTab?.name || feed.tab_name || "Sheet";
  const displayInterval = syncIntervalLabel(syncInterval);
  const syncBusy = syncing || (activeUpload && POLL_STATUSES.has(activeUpload.status));
  const lastSyncUpload =
    activeUpload && POLL_STATUSES.has(activeUpload.status)
      ? activeUpload
      : activeUpload ?? feed.latest_upload ?? null;

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
              {feedTypeLabel(feed.feed_type)} · {displayTabName} · {displayInterval}
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

      <FeedColumnProfileCard profile={supplierProfile} />

      <Card>
        <BlockStack gap="400">
          <Text as="h2" variant="headingMd">
            Google Sheets connection
          </Text>

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
                : "Tabs reload automatically when the URL changes. AI runs only when you change the sheet tab."
            }
          />

          {tabs.length > 0 ? (
            <Select
              label="Sheet tab"
              options={tabOptions}
              value={selectedTabGid}
              onChange={handleTabChange}
              disabled={submitting || loadingPreview || loadingTabs}
              helpText="Column detection runs when you pick a different sheet tab."
            />
          ) : null}

          <ChoiceList
            title="Sync interval"
            choices={SYNC_INTERVAL_OPTIONS.map((option) => ({
              label: option.label,
              value: option.value,
            }))}
            selected={[syncInterval]}
            onChange={(selected) => setSyncInterval(selected[0] || DEFAULT_SYNC_INTERVAL)}
            disabled={submitting}
          />
        </BlockStack>
      </Card>

      <GoogleSheetsPreviewPanel
        preview={preview}
        loading={loadingPreview}
        error={null}
        tabSelected={Boolean(selectedTabGid)}
      />

      <div>
        <Button variant="primary" onClick={handleSaveGoogleSheets} loading={submitting}>
          Save feed
        </Button>
      </div>

      <FeedLastSync
        upload={lastSyncUpload}
        loading={loadState.status === "loading"}
        reviewPendingHref={reviewPendingHref}
      />

      <FeedSyncHistory
        syncs={syncHistory}
        loading={historyLoading}
        reviewPendingHref={reviewPendingHref}
      />

      <div>
        <Button onClick={handleSyncNow} loading={syncBusy} disabled={syncBusy || submitting}>
          Sync now
        </Button>
      </div>
    </BlockStack>
  );
}
