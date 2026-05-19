"use client";

import { useState } from "react";
import {
  Text,
  BlockStack,
  InlineStack,
  Button,
  Badge,
  Banner,
} from "@shopify/polaris";
import {
  confirmReviewMapping,
  rejectReviewMapping,
  manualMatchReviewMapping,
} from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import { formatRelativeTime } from "../lib/format-relative-time";
import VariantPicker, { variantLabel } from "./variant-picker";
import styles from "./review-queue.module.css";

function formatConfidence(score) {
  if (score == null || Number.isNaN(score)) return null;
  return `${Math.round(score * 100)}% match`;
}

function formatQuantities(upload) {
  const quantities = upload?.quantities ?? [];
  if (quantities.length === 0) return "Qty unknown";
  if (quantities.length === 1) return `Qty: ${quantities[0]}`;
  return `Qty: ${quantities.join(", ")}`;
}

export default function ReviewQueueItem({ item, shop, embedded, onResolved }) {
  const [busy, setBusy] = useState(null);
  const [error, setError] = useState(null);
  const [showManual, setShowManual] = useState(false);

  const suggested = item.suggested_variant;
  const confidenceLabel = formatConfidence(item.confidence);

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

  async function handleManualSelect(variant) {
    setBusy("manual");
    setError(null);

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await manualMatchReviewMapping(item.id, variant.id, {
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

  return (
    <div className={styles.item}>
      <BlockStack gap="300">
        <div className={styles.header}>
          <BlockStack gap="100">
            <InlineStack gap="200" blockAlign="center">
              <Text as="p" variant="bodyMd" fontWeight="semibold">
                {item.supplier_code}
              </Text>
              <Badge>{item.supplier?.name}</Badge>
              {confidenceLabel ? (
                <Badge tone="info">{confidenceLabel}</Badge>
              ) : null}
            </InlineStack>
            <Text as="p" variant="bodySm" tone="subdued">
              {formatQuantities(item.supplier_upload)}
              {item.supplier_upload?.created_at
                ? ` · Upload ${formatRelativeTime(item.supplier_upload.created_at)}`
                : ""}
            </Text>
          </BlockStack>
        </div>

        {suggested ? (
          <div className={styles.suggestion}>
            <BlockStack gap="100">
              <Text as="p" variant="bodySm" tone="subdued">
                Suggested match
              </Text>
              <Text as="p" variant="bodyMd">
                {variantLabel(suggested)}
              </Text>
              {suggested.barcode ? (
                <Text as="p" variant="bodySm" tone="subdued">
                  Barcode: {suggested.barcode}
                </Text>
              ) : null}
            </BlockStack>
          </div>
        ) : (
          <Banner tone="warning">
            <p>No automatic suggestion — pick a variant manually below.</p>
          </Banner>
        )}

        {error ? (
          <Banner tone="critical" onDismiss={() => setError(null)}>
            <p>{error}</p>
          </Banner>
        ) : null}

        <div className={styles.actions}>
          {suggested ? (
            <Button
              variant="primary"
              loading={busy === "confirm"}
              disabled={disabled}
              onClick={() => runAction("confirm")}
            >
              Confirm match
            </Button>
          ) : null}
          <Button
            tone="critical"
            loading={busy === "reject"}
            disabled={disabled}
            onClick={() => runAction("reject")}
          >
            Reject (skip permanently)
          </Button>
          <Button
            variant="plain"
            disabled={disabled}
            onClick={() => setShowManual((value) => !value)}
          >
            {showManual ? "Hide manual search" : "Pick different variant"}
          </Button>
        </div>

        {showManual || !suggested ? (
          <div className={styles.manualSection}>
            <VariantPicker
              shop={shop}
              embedded={embedded}
              disabled={disabled}
              onSelect={handleManualSelect}
            />
          </div>
        ) : null}
      </BlockStack>
    </div>
  );
}
