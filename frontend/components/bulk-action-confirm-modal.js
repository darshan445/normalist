"use client";

import { Modal, Text, BlockStack } from "@shopify/polaris";

const ACTION_CONFIG = {
  confirm_selected: {
    title: "Confirm all selected matches?",
    primary: "Confirm All Selected",
    destructive: false,
    description: (count) =>
      `${count} row${count === 1 ? "" : "s"} on this page with a catalog variant selected will be confirmed.`,
  },
  skip_unmatched: {
    title: "Skip all unmatched rows?",
    primary: "Skip Unmatched",
    destructive: true,
    description: (count) =>
      `${count} row${count === 1 ? "" : "s"} on this page without a catalog variant selected will be permanently skipped.`,
  },
};

export default function BulkActionConfirmModal({
  open,
  action,
  selectedCount,
  unmatchedCount,
  loading,
  onConfirm,
  onClose,
}) {
  const config = action ? ACTION_CONFIG[action] : null;
  const count = action === "confirm_selected" ? selectedCount : unmatchedCount;

  if (!config || count === 0) return null;

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={config.title}
      primaryAction={{
        content: config.primary,
        onAction: onConfirm,
        loading,
        destructive: config.destructive,
      }}
      secondaryActions={[
        {
          content: "Cancel",
          onAction: onClose,
          disabled: loading,
        },
      ]}
    >
      <Modal.Section>
        <BlockStack gap="300">
          <Text as="p" variant="bodyMd">
            {config.description(count)}
          </Text>
          <Text as="p" variant="bodySm" tone="subdued">
            Only rows on the current page are included.
          </Text>
        </BlockStack>
      </Modal.Section>
    </Modal>
  );
}
