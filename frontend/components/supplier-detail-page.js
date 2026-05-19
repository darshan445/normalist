"use client";

import { useCallback, useEffect, useState } from "react";
import { useParams, useSearchParams } from "next/navigation";
import { Page, Card, BlockStack, Spinner, Text, Banner } from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { fetchSupplier } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import SupplierDetail from "./supplier-detail";

function toDetailSupplier(apiSupplier) {
  return {
    id: apiSupplier.id,
    name: apiSupplier.name,
    mappedCount: apiSupplier.mapped_count ?? 0,
    pendingCount: apiSupplier.pending_count ?? 0,
    status: apiSupplier.status ?? "ok",
  };
}

export default function SupplierDetailPage() {
  const params = useParams();
  const searchParams = useSearchParams();
  const supplierId = params?.supplierId;
  const { shop, embedded } = pickShopifyParams(searchParams);

  const [detail, setDetail] = useState(null);
  const [loadState, setLoadState] = useState({ status: "loading", error: null });

  const loadDetail = useCallback(async () => {
    if (!supplierId) return;

    setLoadState({ status: "loading", error: null });

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await fetchSupplier(supplierId, { shop, sessionToken });

      if (result.status === 404) {
        setLoadState({ status: "not_found", error: null });
        return;
      }

      if (!result.ok) {
        setLoadState({
          status: "error",
          error: result.data?.message || "Could not load supplier.",
        });
        return;
      }

      setDetail(result.data);
      setLoadState({ status: "ready", error: null });
    } catch (error) {
      setLoadState({ status: "error", error: error.message });
    }
  }, [supplierId, shop, embedded]);

  useEffect(() => {
    loadDetail();
  }, [loadDetail]);

  if (loadState.status === "loading" && !detail) {
    return (
      <Page title="Supplier">
        <Card>
          <BlockStack gap="300" inlineAlign="center">
            <Spinner accessibilityLabel="Loading supplier" />
            <Text as="p" variant="bodyMd" tone="subdued">
              Loading supplier…
            </Text>
          </BlockStack>
        </Card>
      </Page>
    );
  }

  if (loadState.status === "not_found") {
    return (
      <Page title="Supplier not found">
        <Banner tone="warning">
          <p>This supplier does not exist or you do not have access to it.</p>
        </Banner>
      </Page>
    );
  }

  if (loadState.status === "error" && !detail) {
    return (
      <Page title="Supplier">
        <Banner tone="critical" title="Could not load supplier">
          <p>{loadState.error}</p>
        </Banner>
      </Page>
    );
  }

  if (!detail) return null;

  return (
    <SupplierDetail
      supplier={toDetailSupplier(detail.supplier)}
      feeds={detail.feeds ?? []}
      activeMappings={detail.active_mappings ?? []}
      activeMappingsTotal={detail.active_mappings_total ?? 0}
      pendingMappings={detail.pending_mappings ?? []}
      reviewMappings={detail.review_mappings ?? []}
    />
  );
}
