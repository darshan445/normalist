"use client";

import { useMemo, useState } from "react";
import {
  Text,
  Button,
  Badge,
  Banner,
  Select,
} from "@shopify/polaris";
import {
  confirmReviewMapping,
  rejectReviewMapping,
  manualMatchReviewMapping,
} from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import {
  confidenceInfo,
  merchantProductFromVariant,
  variantSelectLabel,
} from "../lib/review-metadata";
import styles from "./review-queue.module.css";

function MetadataCell({ product }) {
  if (!product?.metadata) {
    return (
      <Text as="span" variant="bodySm" tone="subdued">
        —
      </Text>
    );
  }

  return (
    <Text as="span" variant="bodySm">
      {product.metadata}
    </Text>
  );
}

function CodeCell({ value }) {
  return (
    <Text as="span" variant="bodyMd" fontWeight="semibold">
      {value || "—"}
    </Text>
  );
}

export default function ReviewQueueRow({
  item,
  catalogVariants,
  reservedVariantIds = [],
  selectedVariantId,
  onVariantChange,
  shop,
  embedded,
  onResolved,
}) {
  const suggested = item.suggested_variant;
  const confidence = confidenceInfo(item.confidence);

  const variantsForSelect = useMemo(() => {
    const byId = new Map(catalogVariants.map((variant) => [variant.id, variant]));

    if (suggested?.id && !byId.has(suggested.id)) {
      byId.set(suggested.id, {
        id: suggested.id,
        master_sku: suggested.unique_code,
        barcode: suggested.barcode,
        product_title: suggested.product,
        variant_title: suggested.variant,
      });
    }

    return [...byId.values()];
  }, [catalogVariants, suggested]);

  const reservedIds = useMemo(
    () => new Set(reservedVariantIds),
    [reservedVariantIds]
  );

  const availableVariants = useMemo(
    () => variantsForSelect.filter((variant) => !reservedIds.has(variant.id)),
    [variantsForSelect, reservedIds]
  );

  const variantOptions = useMemo(() => {
    const options = availableVariants.map((variant) => ({
      label: variantSelectLabel(variant),
      value: variant.id,
    }));

    return options.sort((left, right) => left.label.localeCompare(right.label));
  }, [availableVariants]);

  const [busy, setBusy] = useState(null);
  const [error, setError] = useState(null);

  const selectedProduct = useMemo(() => {
    if (suggested?.id && selectedVariantId === suggested.id) {
      return suggested;
    }

    const variant =
      variantsForSelect.find((entry) => entry.id === selectedVariantId) ||
      availableVariants.find((entry) => entry.id === selectedVariantId);
    return merchantProductFromVariant(variant);
  }, [variantsForSelect, availableVariants, selectedVariantId, suggested]);

  const selectedVariantLabel = useMemo(() => {
    if (!selectedVariantId) return null;
    if (suggested?.id === selectedVariantId) {
      return variantSelectLabel({
        master_sku: suggested.unique_code,
        product_title: suggested.product,
        variant_title: suggested.variant,
      });
    }
    const variant = variantsForSelect.find((entry) => entry.id === selectedVariantId);
    return variant ? variantSelectLabel(variant) : null;
  }, [selectedVariantId, suggested, variantsForSelect]);

  const supplierProduct = item.supplier_product ?? {
    unique_code: item.supplier_code,
    barcode: null,
    metadata: null,
  };

  async function runAction(action) {
    setBusy(action);
    setError(null);

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      let result;

      if (action === "confirm") {
        result = await confirmReviewMapping(item.id, { shop, sessionToken });
      } else if (action === "reject") {
        result = await rejectReviewMapping(item.id, { shop, sessionToken });
      }

      if (!result?.ok) {
        setError(result?.data?.message || "Action failed. Please try again.");
        return;
      }

      onResolved(item.id);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(null);
    }
  }

  async function handleConfirmSelection() {
    if (!selectedVariantId) {
      setError("Select a merchant variant before confirming.");
      return;
    }

    if (suggested?.id && selectedVariantId === suggested.id) {
      await runAction("confirm");
      return;
    }

    setBusy("manual");
    setError(null);

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await manualMatchReviewMapping(item.id, selectedVariantId, {
        shop,
        sessionToken,
      });

      if (!result?.ok) {
        setError(result?.data?.message || "Could not save manual match.");
        return;
      }

      onResolved(item.id);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(null);
    }
  }

  const disabled = busy !== null;
  const canConfirm = Boolean(selectedVariantId);

  return (
    <>
      <tr className={styles.row}>
        <td>
          <CodeCell value={supplierProduct.unique_code} />
        </td>
        <td>
          <Text as="span" variant="bodySm" tone="subdued">
            {supplierProduct.barcode || "—"}
          </Text>
        </td>
        <td>
          <Text as="span" variant="bodyMd" fontWeight="semibold">
            {item.pending_quantity ?? "—"}
          </Text>
        </td>
        <td className={styles.supplierLastCell}>
          <MetadataCell product={supplierProduct} />
        </td>

        <td className={styles.merchantMatchCell}>
          {selectedVariantId && selectedVariantLabel ? (
            <div className={styles.selectedMatch}>
              <Text as="p" variant="bodySm">
                {selectedVariantLabel}
              </Text>
              <Button
                variant="plain"
                size="slim"
                disabled={disabled}
                onClick={() => onVariantChange("")}
              >
                Change
              </Button>
            </div>
          ) : (
            <Select
              label="Merchant match"
              labelHidden
              options={[
                { label: "Select SKU or barcode…", value: "" },
                ...variantOptions,
              ]}
              value=""
              onChange={onVariantChange}
              disabled={disabled}
            />
          )}
        </td>
        <td>
          <Text as="span" variant="bodySm" tone="subdued">
            {selectedProduct?.barcode || "—"}
          </Text>
        </td>
        <td className={styles.merchantLastCell}>
          <MetadataCell product={selectedProduct} />
        </td>

        <td>
          <div className={styles.cellStack}>
            <Badge>{item.supplier?.name}</Badge>
            <Badge tone={confidence.tone}>{confidence.label}</Badge>
            {suggested ? (
              <Badge tone="success">Suggested</Badge>
            ) : null}
          </div>
        </td>

        <td className={styles.actionsCell}>
          <div className={styles.rowActions}>
            <Button
              variant="primary"
              size="slim"
              loading={busy === "confirm" || busy === "manual"}
              disabled={disabled || !canConfirm}
              onClick={handleConfirmSelection}
            >
              Confirm
            </Button>
            <Button
              tone="critical"
              size="slim"
              loading={busy === "reject"}
              disabled={disabled}
              onClick={() => runAction("reject")}
            >
              Reject
            </Button>
          </div>
        </td>
      </tr>

      {error ? (
        <tr>
          <td colSpan={9} className={styles.errorCell}>
            <Banner tone="critical" onDismiss={() => setError(null)}>
              <p>{error}</p>
            </Banner>
          </td>
        </tr>
      ) : null}
    </>
  );
}
