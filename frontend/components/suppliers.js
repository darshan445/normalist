"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Button,
  Spinner,
  Banner,
  EmptyState,
} from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { fetchSuppliers, createSupplier } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import AddSupplierModal from "./add-supplier-modal";
import MappingStatsGrid from "./mapping-stats-grid";
import styles from "./suppliers.module.css";

function SupplierStatus({ status }) {
  if (status === "warning") {
    return (
      <span className={styles.supplierStatus} aria-label="Has pending mappings">
        ⚠️
      </span>
    );
  }
  return (
    <span className={styles.supplierStatus} aria-label="All mappings resolved">
      ✅
    </span>
  );
}

export default function Suppliers() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { shop, embedded } = pickShopifyParams(searchParams);
  const shopifyParams = pickShopifyParams(searchParams);

  const [suppliers, setSuppliers] = useState([]);
  const [loadState, setLoadState] = useState({ status: "loading", error: null });
  const [modalOpen, setModalOpen] = useState(false);

  const loadSuppliers = useCallback(async () => {
    setLoadState({ status: "loading", error: null });

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await fetchSuppliers({ shop, sessionToken });

      if (!result.ok) {
        setLoadState({
          status: "error",
          error: result.data?.message || "Could not load suppliers.",
        });
        return;
      }

      setSuppliers(result.data?.suppliers ?? []);
      setLoadState({ status: "ready", error: null });
    } catch (error) {
      setLoadState({ status: "error", error: error.message });
    }
  }, [shop, embedded]);

  useEffect(() => {
    loadSuppliers();
  }, [loadSuppliers]);

  useEffect(() => {
    if (searchParams?.get("create") === "1") {
      setModalOpen(true);
    }
  }, [searchParams]);

  const handleCreate = useCallback(
    async (name) => {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await createSupplier({ name }, { shop, sessionToken });

      if (!result.ok) {
        const message =
          result.data?.errors?.join(", ") ||
          result.data?.message ||
          "Could not create supplier.";
        throw new Error(message);
      }

      await loadSuppliers();
      return result.data.supplier;
    },
    [shop, embedded, loadSuppliers]
  );

  const handleModalClose = useCallback(
    (created) => {
      setModalOpen(false);
      if (created?.id) {
        const href = shopifyNavHref(`/suppliers/${created.id}`, shopifyParams);
        router.push(href);
      }
    },
    [router, shopifyParams]
  );

  return (
    <BlockStack gap="500">
      <InlineStack align="space-between" blockAlign="center">
        <Text as="h1" variant="headingLg">
          Suppliers
        </Text>
        <Button variant="primary" onClick={() => setModalOpen(true)}>
          Add Supplier
        </Button>
      </InlineStack>

      {loadState.status === "error" ? (
        <Banner tone="critical" title="Could not load suppliers">
          <p>{loadState.error}</p>
        </Banner>
      ) : null}

      {loadState.status === "loading" ? (
        <BlockStack gap="300" inlineAlign="center">
          <Spinner accessibilityLabel="Loading suppliers" />
          <Text as="p" variant="bodyMd" tone="subdued">
            Loading suppliers…
          </Text>
        </BlockStack>
      ) : suppliers.length === 0 ? (
        <Card>
          <EmptyState
            heading="No suppliers yet"
            action={{
              content: "Add supplier",
              onAction: () => setModalOpen(true),
            }}
          >
            <p>Add a supplier to upload stock files and map product codes.</p>
          </EmptyState>
        </Card>
      ) : (
        <Card padding="0">
          <div className={styles.supplierList}>
            {suppliers.map((supplier) => {
              const detailHref = shopifyNavHref(
                `/suppliers/${supplier.id}`,
                shopifyParams
              );

              return (
                <Link
                  key={supplier.id}
                  href={detailHref}
                  className={styles.supplierRow}
                >
                  <div className={styles.supplierRowMain}>
                    <Text as="p" variant="bodyMd" fontWeight="semibold">
                      {supplier.name}
                    </Text>
                    <MappingStatsGrid
                      mapped={supplier.mapped_count ?? 0}
                      pending={supplier.pending_count ?? 0}
                      skipped={supplier.skipped_count ?? 0}
                      compact
                    />
                  </div>
                  <SupplierStatus status={supplier.status} />
                </Link>
              );
            })}
          </div>
        </Card>
      )}

      <AddSupplierModal
        open={modalOpen}
        onClose={handleModalClose}
        onCreate={handleCreate}
      />
    </BlockStack>
  );
}
