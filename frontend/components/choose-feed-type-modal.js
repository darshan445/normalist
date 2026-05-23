"use client";

import { Modal, ChoiceList, Banner, Text, BlockStack } from "@shopify/polaris";
import { useState, useCallback, useEffect, useMemo } from "react";
import { buildFeedTypeChoices, availableFeedTypes } from "../lib/feed-helpers";

export default function ChooseFeedTypeModal({
  open,
  onClose,
  supplierId,
  shopifyParams,
  existingFeeds = [],
}) {
  const usedFeedTypes = useMemo(
    () => existingFeeds.map((feed) => feed.feed_type),
    [existingFeeds]
  );
  const choices = useMemo(() => buildFeedTypeChoices(usedFeedTypes), [usedFeedTypes]);
  const available = useMemo(() => availableFeedTypes(usedFeedTypes), [usedFeedTypes]);

  const [feedType, setFeedType] = useState([]);

  useEffect(() => {
    if (!open) return;
    const firstAvailable = available[0] || "file_upload";
    setFeedType([firstAvailable]);
  }, [open, available]);

  const handleClose = useCallback(() => {
    onClose();
  }, [onClose]);

  const handleContinue = useCallback(() => {
    const selected = feedType[0];
    if (!selected || !available.includes(selected)) return;

    const params = new URLSearchParams();
    params.set("type", selected);
    if (shopifyParams.shop) params.set("shop", shopifyParams.shop);
    if (shopifyParams.host) params.set("host", shopifyParams.host);
    if (shopifyParams.embedded) params.set("embedded", "1");
    if (shopifyParams.idToken) params.set("id_token", shopifyParams.idToken);

    const href = `/suppliers/${supplierId}/feeds/setup?${params.toString()}`;

    handleClose();
    window.location.assign(href);
  }, [feedType, available, supplierId, shopifyParams, handleClose]);

  const allTypesAdded = available.length === 0;

  return (
    <Modal
      open={open}
      onClose={handleClose}
      title="Add feed"
      primaryAction={{
        content: "Continue",
        onAction: handleContinue,
        disabled: allTypesAdded,
      }}
      secondaryActions={[{ content: "Cancel", onAction: handleClose }]}
    >
      <Modal.Section>
        <BlockStack gap="400">
          {allTypesAdded ? (
            <Banner tone="info">
              <p>
                This supplier already has both feed types. Open an existing feed to
                upload files or update its Google Sheets URL.
              </p>
            </Banner>
          ) : (
            <Text as="p" variant="bodySm" tone="subdued">
              Each feed type can only be added once per supplier.
            </Text>
          )}
          <ChoiceList
            title="Feed type"
            choices={choices}
            selected={feedType}
            onChange={setFeedType}
          />
        </BlockStack>
      </Modal.Section>
    </Modal>
  );
}
