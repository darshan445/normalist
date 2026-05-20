"use client";

import { Modal, Text, BlockStack } from "@shopify/polaris";

const ACTION_CONFIG = {
  confirm_suggested: {
    title: "Confirm all suggested matches?",
    primary: "Confirm all suggested",
    destructive: false,
    description:
      "Every review item with a suggestion at 50% confidence or higher will be mapped using the suggested variant. This cannot be undone from the review queue.",
  },
  reject_suggested: {
    title: "Skip all suggested items?",
    primary: "Skip all suggested",
    destructive: true,
    description:
      "Every suggested review item (50% confidence or higher) will be permanently skipped and will not appear in future uploads.",
  },
  reject_unsuggested: {
    title: "Skip all not suggested items?",
    primary: "Skip all not suggested",
    destructive: true,
    description:
      "Every review item below 50% confidence will be permanently skipped and will not appear in future uploads.",
  },
};

function scopeLabel({ supplierName, action }) {
  const supplierPart = supplierName ? `supplier “${supplierName}”` : "all suppliers";

  if (action === "reject_unsuggested") {
    return `${supplierPart}, items below 50% confidence`;
  }

  return `${supplierPart}, suggested items (50% confidence or higher)`;
}

export default function BulkActionConfirmModal({
  open,
  action,
  supplierName,
  loading,
  onConfirm,
  onClose,
}) {
  const config = action ? ACTION_CONFIG[action] : null;

  if (!config) return null;

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
            {config.description}
          </Text>
          <Text as="p" variant="bodySm" tone="subdued">
            Scope: {scopeLabel({ supplierName, action })}. This runs across all
            pages, not just the rows visible on this page.
          </Text>
        </BlockStack>
      </Modal.Section>
    </Modal>
  );
}
