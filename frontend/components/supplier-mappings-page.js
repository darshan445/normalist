"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Button,
  Badge,
  Spinner,
  Banner,
  EmptyState,
  Pagination,
  Select,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { fetchSupplierMappings } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import MappingStatsGrid from "./mapping-stats-grid";
import styles from "./supplier-detail.module.css";
import mappingStyles from "./supplier-mappings.module.css";

const PER_PAGE = 50;

const STATUS_TABS = [
  { label: "All", value: "all" },
  { label: "Mapped", value: "mapped" },
  { label: "Pending", value: "pending" },
  { label: "Skipped", value: "skipped" },
];

function MappingStatusBadge({ status }) {
  if (status === "mapped") return <Badge tone="success">mapped</Badge>;
  if (status === "pending") return <Badge tone="warning">pending</Badge>;
  if (status === "skipped") return <Badge>skipped</Badge>;
  if (status === "review") return <Badge tone="attention">review</Badge>;
  return <Badge>{status}</Badge>;
}

export default function SupplierMappingsPage() {
  const router = useRouter();
  const params = useParams();
  const searchParams = useSearchParams();
  const supplierId = params?.supplierId;
  const { shop, embedded } = pickShopifyParams(searchParams);
  const shopifyParams = pickShopifyParams(searchParams);

  const statusFromUrl = searchParams.get("status") || "all";
  const [statusFilter, setStatusFilter] = useState(statusFromUrl);
  const [page, setPage] = useState(1);
  const [data, setData] = useState(null);
  const [loadState, setLoadState] = useState({ status: "loading", error: null });

  useEffect(() => {
    setStatusFilter(statusFromUrl);
    setPage(1);
  }, [statusFromUrl]);

  const loadMappings = useCallback(async () => {
    if (!supplierId) return;

    setLoadState({ status: "loading", error: null });

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await fetchSupplierMappings(supplierId, {
        page,
        perPage: PER_PAGE,
        status: statusFilter,
        shop,
        sessionToken,
      });

      if (result.status === 404) {
        setLoadState({ status: "not_found", error: null });
        return;
      }

      if (!result.ok) {
        setLoadState({
          status: "error",
          error: result.data?.message || "Could not load mappings.",
        });
        return;
      }

      setData(result.data);
      setLoadState({ status: "ready", error: null });
    } catch (error) {
      setLoadState({ status: "error", error: error.message });
    }
  }, [supplierId, page, statusFilter, shop, embedded]);

  useEffect(() => {
    loadMappings();
  }, [loadMappings]);

  const supplierHref = shopifyNavHref(`/suppliers/${supplierId}`, shopifyParams);
  const reviewPendingHref = shopifyNavHref(
    `/review?supplier_id=${supplierId}`,
    shopifyParams
  );

  const handleStatusChange = (value) => {
    setStatusFilter(value);
    setPage(1);
    router.replace(
      shopifyNavHref(`/suppliers/${supplierId}/mappings?status=${value}`, shopifyParams)
    );
  };

  if (loadState.status === "loading" && !data) {
    return (
      <BlockStack gap="300" inlineAlign="center">
        <Spinner accessibilityLabel="Loading mappings" />
        <Text as="p" variant="bodyMd" tone="subdued">
          Loading mappings…
        </Text>
      </BlockStack>
    );
  }

  if (loadState.status === "not_found") {
    return (
      <Banner tone="warning">
        <p>Supplier not found.</p>
        <p>
          <Link href={shopifyNavHref("/suppliers", shopifyParams)}>Back to suppliers</Link>
        </p>
      </Banner>
    );
  }

  if (loadState.status === "error" && !data) {
    return (
      <Banner tone="critical" title="Could not load mappings">
        <p>{loadState.error}</p>
      </Banner>
    );
  }

  const supplier = data?.supplier;
  const mappings = data?.mappings ?? [];
  const pagination = data?.pagination ?? { page: 1, total_pages: 0, total_count: 0 };

  return (
    <BlockStack gap="500">
      <BlockStack gap="200">
        <Link href={supplierHref} className={styles.backLink}>
          ← {supplier?.name || "Supplier"}
        </Link>
        <InlineStack align="space-between" blockAlign="center">
          <Text as="h1" variant="headingLg">
            All mappings
          </Text>
          {pagination.total_count > 0 && statusFilter === "pending" ? (
            <Button url={reviewPendingHref}>Review pending</Button>
          ) : null}
        </InlineStack>
        <Text as="p" variant="bodySm" tone="subdued">
          {pagination.total_count} code{pagination.total_count === 1 ? "" : "s"}
          {statusFilter !== "all" ? ` · ${statusFilter}` : ""}
        </Text>
      </BlockStack>

      <Card>
        <BlockStack gap="300">
          <Select
            label="Show"
            options={STATUS_TABS}
            value={statusFilter}
            onChange={handleStatusChange}
          />

          {mappings.length === 0 ? (
            <EmptyState heading="No mappings in this view">
              <p>Try another filter or upload a supplier stock file.</p>
            </EmptyState>
          ) : (
            <div className={mappingStyles.table}>
              <div className={mappingStyles.tableHeader}>
                <span>Supplier code</span>
                <span>Master SKU</span>
                <span>Status</span>
              </div>
              {mappings.map((row) => (
                <div key={row.id} className={mappingStyles.tableRow}>
                  <Text as="span" variant="bodyMd" fontWeight="semibold">
                    {row.supplier_code}
                  </Text>
                  <Text as="span" variant="bodyMd">
                    {row.master_sku || "—"}
                  </Text>
                  <MappingStatusBadge status={row.status} />
                </div>
              ))}
            </div>
          )}

          {pagination.total_pages > 1 ? (
            <InlineStack align="center">
              <Pagination
                hasPrevious={page > 1}
                onPrevious={() => setPage((current) => Math.max(1, current - 1))}
                hasNext={page < pagination.total_pages}
                onNext={() =>
                  setPage((current) => Math.min(pagination.total_pages, current + 1))
                }
                label={`Page ${page} of ${pagination.total_pages}`}
              />
            </InlineStack>
          ) : null}
        </BlockStack>
      </Card>
    </BlockStack>
  );
}
