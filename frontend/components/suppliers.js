"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Button,
} from "@shopify/polaris";
import { STATIC_SUPPLIERS } from "../lib/suppliers-static";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
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
  const searchParams = useSearchParams();
  const shopifyParams = pickShopifyParams(searchParams);

  return (
    <BlockStack gap="500">
      <InlineStack align="space-between" blockAlign="center">
        <Text as="h1" variant="headingLg">
          Suppliers
        </Text>
        <Button variant="primary">Add Supplier</Button>
      </InlineStack>

      <Card padding="0">
        <div className={styles.supplierList}>
          {STATIC_SUPPLIERS.map((supplier) => {
            const detailHref = shopifyNavHref(
              `/suppliers/${supplier.id}`,
              shopifyParams
            );

            return (
              <Link key={supplier.id} href={detailHref} className={styles.supplierRow}>
                <div className={styles.supplierRowMain}>
                  <Text as="p" variant="bodyMd" fontWeight="semibold">
                    {supplier.name}
                  </Text>
                  <Text as="p" variant="bodySm" tone="subdued">
                    {supplier.mappedCount} mapped · {supplier.pendingCount} pending
                  </Text>
                </div>
                <SupplierStatus status={supplier.status} />
              </Link>
            );
          })}
        </div>
      </Card>
    </BlockStack>
  );
}
