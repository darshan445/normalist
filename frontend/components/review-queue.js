"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Spinner,
  Banner,
  EmptyState,
  Pagination,
  Select,
  TextField,
  Button,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import {
  fetchReviewQueue,
  fetchSuppliers,
  fetchCatalog,
  bulkConfirmReviewQueue,
  bulkRejectReviewQueue,
} from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import ReviewQueueRow from "./review-queue-row";
import BulkActionConfirmModal from "./bulk-action-confirm-modal";
import styles from "./review-queue.module.css";

const PER_PAGE = 25;

export default function ReviewQueue() {
  const searchParams = useSearchParams();
  const { shop, embedded } = pickShopifyParams(searchParams);
  const supplierFilterFromUrl = searchParams.get("supplier_id") || "";

  const [page, setPage] = useState(1);
  const [supplierFilter, setSupplierFilter] = useState(supplierFilterFromUrl);
  const [suggestionFilter, setSuggestionFilter] = useState("");
  const [items, setItems] = useState([]);
  const [bulkBusy, setBulkBusy] = useState(null);
  const [bulkMessage, setBulkMessage] = useState(null);
  const [pendingBulkAction, setPendingBulkAction] = useState(null);
  const [catalogVariants, setCatalogVariants] = useState([]);
  const [catalogFilter, setCatalogFilter] = useState("");
  const [pagination, setPagination] = useState({
    page: 1,
    per_page: PER_PAGE,
    total_count: 0,
    total_pages: 0,
  });
  const [suppliers, setSuppliers] = useState([]);
  const [loadState, setLoadState] = useState({ status: "loading", error: null });

  useEffect(() => {
    setSupplierFilter(supplierFilterFromUrl);
    setPage(1);
  }, [supplierFilterFromUrl]);

  const loadSuppliers = useCallback(async () => {
    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await fetchSuppliers({ shop, sessionToken });
      if (result.ok) {
        setSuppliers(result.data?.suppliers ?? []);
      }
    } catch {
      setSuppliers([]);
    }
  }, [shop, embedded]);

  const loadCatalog = useCallback(async () => {
    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await fetchCatalog("/api/v1/catalog", { shop, sessionToken });
      if (result.ok) {
        setCatalogVariants(result.data?.variants ?? []);
      }
    } catch {
      setCatalogVariants([]);
    }
  }, [shop, embedded]);

  const loadQueue = useCallback(async () => {
    setLoadState({ status: "loading", error: null });

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await fetchReviewQueue({
        page,
        perPage: PER_PAGE,
        supplierId: supplierFilter || undefined,
        suggestion: suggestionFilter || undefined,
        shop,
        sessionToken,
      });

      if (!result.ok) {
        setLoadState({
          status: "error",
          error: result.data?.message || "Could not load review queue.",
        });
        return;
      }

      setItems(result.data?.items ?? []);
      setPagination(result.data?.pagination ?? pagination);
      setLoadState({ status: "ready", error: null });
    } catch (error) {
      setLoadState({ status: "error", error: error.message });
    }
  }, [page, supplierFilter, suggestionFilter, shop, embedded]);

  useEffect(() => {
    loadSuppliers();
    loadCatalog();
  }, [loadSuppliers, loadCatalog]);

  useEffect(() => {
    loadQueue();
  }, [loadQueue]);

  function handleResolved() {
    loadQueue();
  }

  function requestBulkAction(action) {
    setPendingBulkAction(action);
  }

  function closeBulkConfirm() {
    if (bulkBusy) return;
    setPendingBulkAction(null);
  }

  async function runBulkAction(action) {
    setBulkBusy(action);
    setBulkMessage(null);

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const base = {
        supplierId: supplierFilter || undefined,
        shop,
        sessionToken,
      };

      let result;
      if (action === "confirm_suggested") {
        result = await bulkConfirmReviewQueue({ ...base, suggestion: "suggested" });
      } else if (action === "reject_suggested") {
        result = await bulkRejectReviewQueue({ ...base, suggestion: "suggested" });
      } else if (action === "reject_unsuggested") {
        result = await bulkRejectReviewQueue({ ...base, suggestion: "unsuggested" });
      }

      if (!result?.ok) {
        setBulkMessage({
          tone: "critical",
          text: result?.data?.message || "Bulk action failed.",
        });
        return;
      }

      const { succeeded = 0, failed = [] } = result.data ?? {};
      const tone = failed.length > 0 ? "warning" : "success";
      const failedNote =
        failed.length > 0 ? ` ${failed.length} could not be processed.` : "";

      setBulkMessage({
        tone,
        text: `${succeeded} item${succeeded === 1 ? "" : "s"} updated.${failedNote}`,
      });
      loadQueue();
    } catch (error) {
      setBulkMessage({ tone: "critical", text: error.message });
    } finally {
      setBulkBusy(null);
      setPendingBulkAction(null);
    }
  }

  const filteredCatalogVariants = useMemo(() => {
    const query = catalogFilter.trim().toLowerCase();
    if (!query) return catalogVariants;

    return catalogVariants.filter((variant) => {
      const haystack = [
        variant.master_sku,
        variant.barcode,
        variant.product_title,
        variant.variant_title,
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();

      return haystack.includes(query);
    });
  }, [catalogFilter, catalogVariants]);

  const supplierOptions = [
    { label: "All suppliers", value: "" },
    ...suppliers.map((supplier) => ({ label: supplier.name, value: supplier.id })),
  ];

  const suggestionOptions = [
    { label: "All items", value: "" },
    { label: "Suggested only", value: "suggested" },
    { label: "Not suggested", value: "unsuggested" },
  ];

  const selectedSupplierName =
    suppliers.find((supplier) => supplier.id === supplierFilter)?.name ?? null;

  return (
    <BlockStack gap="500">
      <BlockStack gap="200">
        <Text as="h1" variant="headingLg">
          Review queue
        </Text>
        <Text as="p" variant="bodyMd" tone="subdued">
          Match supplier codes to your catalog. Rows are sorted from lowest to highest
          confidence. Suggestions at 50% or above are pre-selected.
        </Text>
      </BlockStack>

      <InlineStack gap="300" wrap>
        <div className={styles.filterField}>
          <Select
            label="Supplier"
            options={supplierOptions}
            value={supplierFilter}
            onChange={(value) => {
              setSupplierFilter(value);
              setPage(1);
            }}
          />
        </div>
        <div className={styles.filterField}>
          <Select
            label="Show"
            options={suggestionOptions}
            value={suggestionFilter}
            onChange={(value) => {
              setSuggestionFilter(value);
              setPage(1);
            }}
          />
        </div>
      </InlineStack>

      {bulkMessage ? (
        <Banner tone={bulkMessage.tone} onDismiss={() => setBulkMessage(null)}>
          <p>{bulkMessage.text}</p>
        </Banner>
      ) : null}

      {loadState.status === "error" ? (
        <Banner tone="critical" title="Could not load review queue">
          <p>{loadState.error}</p>
        </Banner>
      ) : null}

      {loadState.status === "loading" && items.length === 0 ? (
        <BlockStack gap="300" inlineAlign="center">
          <Spinner accessibilityLabel="Loading review queue" />
          <Text as="p" variant="bodyMd" tone="subdued">
            Loading review queue…
          </Text>
        </BlockStack>
      ) : items.length === 0 && loadState.status === "ready" ? (
        <Card>
          <EmptyState heading="Nothing to review">
            <p>All supplier codes are mapped or skipped. You&apos;re up to date.</p>
          </EmptyState>
        </Card>
      ) : (
        <>
          <Text as="p" variant="bodySm" tone="subdued">
            {pagination.total_count} item{pagination.total_count === 1 ? "" : "s"} awaiting
            review
          </Text>

          <Card>
            <BlockStack gap="300">
              <Text as="h2" variant="headingSm">
                Bulk actions
              </Text>
              <Text as="p" variant="bodySm" tone="subdued">
                Bulk actions use the supplier filter above. Each action targets a fixed
                group (suggested or not suggested) across all pages.
              </Text>
              <InlineStack gap="200" wrap>
                <Button
                  variant="primary"
                  disabled={bulkBusy !== null}
                  onClick={() => requestBulkAction("confirm_suggested")}
                >
                  Confirm all suggested
                </Button>
                <Button
                  tone="critical"
                  disabled={bulkBusy !== null}
                  onClick={() => requestBulkAction("reject_suggested")}
                >
                  Skip all suggested
                </Button>
                <Button
                  tone="critical"
                  disabled={bulkBusy !== null}
                  onClick={() => requestBulkAction("reject_unsuggested")}
                >
                  Skip all not suggested
                </Button>
              </InlineStack>
            </BlockStack>
          </Card>

          <TextField
            label="Filter catalog matches"
            value={catalogFilter}
            onChange={setCatalogFilter}
            placeholder="Search SKU, barcode, product, or variant…"
            autoComplete="off"
            helpText={`${filteredCatalogVariants.length} variant${
              filteredCatalogVariants.length === 1 ? "" : "s"
            } shown in match dropdowns`}
          />

          <Card padding="0">
            <div className={styles.tableScroll}>
              <table className={styles.mappingTable}>
                <thead>
                  <tr className={styles.groupHeaderRow}>
                    <th colSpan={4} className={styles.supplierGroup}>
                      Supplier
                    </th>
                    <th colSpan={3} className={styles.merchantGroup}>
                      Your catalog
                    </th>
                    <th colSpan={1}>Review</th>
                    <th colSpan={1} />
                  </tr>
                  <tr>
                    <th>Unique code</th>
                    <th>Barcode</th>
                    <th>Qty</th>
                    <th>Details</th>
                    <th>Match</th>
                    <th>Barcode</th>
                    <th>Details</th>
                    <th>Info</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {items.map((item) => (
                    <ReviewQueueRow
                      key={item.id}
                      item={item}
                      catalogVariants={filteredCatalogVariants}
                      shop={shop}
                      embedded={embedded}
                      onResolved={handleResolved}
                    />
                  ))}
                </tbody>
              </table>
            </div>
          </Card>

          {pagination.total_pages > 1 ? (
            <div className={styles.pagination}>
              <Pagination
                hasPrevious={page > 1}
                onPrevious={() => setPage((current) => current - 1)}
                hasNext={page < pagination.total_pages}
                onNext={() => setPage((current) => current + 1)}
                label={`Page ${page} of ${pagination.total_pages}`}
              />
            </div>
          ) : null}
        </>
      )}
      <BulkActionConfirmModal
        open={pendingBulkAction !== null}
        action={pendingBulkAction}
        supplierName={selectedSupplierName}
        loading={bulkBusy !== null}
        onConfirm={() => runBulkAction(pendingBulkAction)}
        onClose={closeBulkConfirm}
      />
    </BlockStack>
  );
}
