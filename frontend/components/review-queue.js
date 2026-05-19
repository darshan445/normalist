"use client";

import { useCallback, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  Spinner,
  Banner,
  EmptyState,
  Pagination,
  Select,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { fetchReviewQueue, fetchSuppliers } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import ReviewQueueItem from "./review-queue-item";
import styles from "./review-queue.module.css";

const PER_PAGE = 25;

export default function ReviewQueue() {
  const searchParams = useSearchParams();
  const { shop, embedded } = pickShopifyParams(searchParams);
  const supplierFilterFromUrl = searchParams.get("supplier_id") || "";

  const [page, setPage] = useState(1);
  const [supplierFilter, setSupplierFilter] = useState(supplierFilterFromUrl);
  const [items, setItems] = useState([]);
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

  const loadQueue = useCallback(async () => {
    setLoadState({ status: "loading", error: null });

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await fetchReviewQueue({
        page,
        perPage: PER_PAGE,
        supplierId: supplierFilter || undefined,
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
  }, [page, supplierFilter, shop, embedded]);

  useEffect(() => {
    loadSuppliers();
  }, [loadSuppliers]);

  useEffect(() => {
    loadQueue();
  }, [loadQueue]);

  function handleResolved() {
    loadQueue();
  }

  const supplierOptions = [
    { label: "All suppliers", value: "" },
    ...suppliers.map((supplier) => ({ label: supplier.name, value: supplier.id })),
  ];

  return (
    <BlockStack gap="500">
      <BlockStack gap="200">
        <Text as="h1" variant="headingLg">
          Review queue
        </Text>
        <Text as="p" variant="bodyMd" tone="subdued">
          Confirm AI suggestions, reject codes you don&apos;t carry, or pick the correct
          variant manually.
        </Text>
      </BlockStack>

      <Select
        label="Supplier"
        options={supplierOptions}
        value={supplierFilter}
        onChange={(value) => {
          setSupplierFilter(value);
          setPage(1);
        }}
      />

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

          <Card padding="0">
            {items.map((item) => (
              <ReviewQueueItem
                key={item.id}
                item={item}
                shop={shop}
                embedded={embedded}
                onResolved={handleResolved}
              />
            ))}
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
    </BlockStack>
  );
}
