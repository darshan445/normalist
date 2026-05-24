"use client";

import { useState } from "react";
import { useSearchParams } from "next/navigation";
import { Button, Modal, Text, BlockStack } from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { fetchSessionToken } from "../lib/shopify-session-token";
import { cancelSubscription } from "../lib/cancel-subscription";
import { formatBillingDate } from "../lib/format-billing-date";
import { useTrialStatus } from "../lib/trial-status-context";

export default function CancelSubscriptionButton({ accessUntil, onError, onSuccess }) {
  const searchParams = useSearchParams();
  const shopifyParams = pickShopifyParams(searchParams);
  const { reload, trialStatus } = useTrialStatus();
  const [modalOpen, setModalOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleClose = () => {
    if (!loading) setModalOpen(false);
  };

  const handleConfirm = async () => {
    setLoading(true);
    onError?.(null);

    try {
      const sessionToken = await fetchSessionToken();
      await cancelSubscription({
        shop: shopifyParams.shop,
        sessionToken,
      });
      await reload();
      setModalOpen(false);
      onSuccess?.();
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Could not cancel subscription.";
      onError?.(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Button tone="critical" onClick={() => setModalOpen(true)}>
        Cancel subscription
      </Button>

      <Modal
        open={modalOpen}
        onClose={handleClose}
        title="Cancel subscription?"
        primaryAction={{
          content: "Cancel subscription",
          onAction: handleConfirm,
          loading,
          destructive: true,
        }}
        secondaryActions={[
          {
            content: "Keep subscription",
            onAction: handleClose,
            disabled: loading,
          },
        ]}
      >
        <Modal.Section>
          <BlockStack gap="300">
            <Text as="p" variant="bodyMd">
              Your subscription will be cancelled and will not auto-renew. You will keep
              full access until{" "}
              {formatBillingDate(accessUntil || trialStatus?.billing_on)}.
            </Text>
            <Text as="p" variant="bodySm" tone="subdued">
              Future billing charges will be stopped in Shopify.
            </Text>
          </BlockStack>
        </Modal.Section>
      </Modal>
    </>
  );
}
