"use client";

import { useState } from "react";
import { Text, Select, Button } from "@shopify/polaris";
import { VARIANT_SEARCH_OPTIONS } from "../lib/mappings-static";
import styles from "./mappings.module.css";
import detailStyles from "./supplier-detail.module.css";

export default function MappingRow({ mapping }) {
  const [variant, setVariant] = useState("");

  return (
    <div className={styles.mappingRow}>
      <div className={styles.codeBlock}>
        <Text as="p" variant="bodyMd" fontWeight="semibold">
          {mapping.code}
        </Text>
        <Text as="p" variant="bodySm" tone="subdued">
          Qty: {mapping.quantity}
        </Text>
      </div>

      <div className={styles.actionBlock}>
        <Select
          label="Variant"
          labelHidden
          options={VARIANT_SEARCH_OPTIONS}
          value={variant}
          onChange={setVariant}
        />
        <div className={detailStyles.skipActions}>
          <Button size="slim" variant="plain" tone="critical">
            Skip permanently
          </Button>
          <Button size="slim" variant="plain">
            Skip now
          </Button>
        </div>
      </div>
    </div>
  );
}

