"use client";

import { useState, useCallback } from "react";
import { Modal, TextField, BlockStack, Banner } from "@shopify/polaris";

export default function AddSupplierModal({ open, onClose, onCreate }) {
  const [name, setName] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);

  const reset = useCallback(() => {
    setName("");
    setError(null);
    setSubmitting(false);
  }, []);

  const handleClose = useCallback(() => {
    if (submitting) return;
    reset();
    onClose();
  }, [onClose, reset, submitting]);

  const handleSubmit = useCallback(async () => {
    const trimmed = name.trim();
    if (!trimmed) {
      setError("Supplier name is required.");
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      const created = await onCreate(trimmed);
      reset();
      onClose(created);
    } catch (err) {
      setError(err.message || "Could not create supplier.");
      setSubmitting(false);
    }
  }, [name, onClose, onCreate, reset]);

  return (
    <Modal
      open={open}
      onClose={handleClose}
      title="Add supplier"
      primaryAction={{
        content: "Create supplier",
        onAction: handleSubmit,
        loading: submitting,
      }}
      secondaryActions={[{ content: "Cancel", onAction: handleClose, disabled: submitting }]}
    >
      <Modal.Section>
        <BlockStack gap="400">
          {error ? (
            <Banner tone="critical" onDismiss={() => setError(null)}>
              <p>{error}</p>
            </Banner>
          ) : null}
          <TextField
            label="Supplier name"
            value={name}
            onChange={setName}
            autoComplete="off"
            placeholder="e.g. Acme Wholesale"
            disabled={submitting}
          />
        </BlockStack>
      </Modal.Section>
    </Modal>
  );
}
