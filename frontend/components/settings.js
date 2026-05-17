"use client";

import { useState } from "react";
import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Badge,
  Select,
} from "@shopify/polaris";
import { useAppSession } from "../lib/session-context";
import {
  DEFAULT_STALE_MAPPING_DAYS,
  PLATFORM_LAST_SYNC_LABEL,
  STALE_MAPPING_DAY_OPTIONS,
} from "../lib/settings-static";

export default function Settings() {
  const session = useAppSession();
  const [staleMappingDays, setStaleMappingDays] = useState(DEFAULT_STALE_MAPPING_DAYS);

  const storeDomain =
    session?.merchant?.platform_domain || "your-store.myshopify.com";
  const staleDaysLabel =
    STALE_MAPPING_DAY_OPTIONS.find((option) => option.value === staleMappingDays)?.label ||
    `${staleMappingDays} days`;

  return (
    <BlockStack gap="500">
      <Text as="h1" variant="headingLg">
        Settings
      </Text>

      <BlockStack gap="300">
        <Text as="h2" variant="headingMd">
          Platform Connection
        </Text>
        <Card>
          <BlockStack gap="300">
            <InlineStack align="space-between" blockAlign="center">
              <Text as="p" variant="bodyMd" fontWeight="semibold">
                Shopify
              </Text>
              <Badge tone="success">✅ Connected</Badge>
            </InlineStack>
            <BlockStack gap="100">
              <Text as="p" variant="bodyMd">
                Store: {storeDomain}
              </Text>
              <Text as="p" variant="bodySm" tone="subdued">
                Last sync: {PLATFORM_LAST_SYNC_LABEL}
              </Text>
            </BlockStack>
          </BlockStack>
        </Card>
      </BlockStack>

      <BlockStack gap="300">
        <Text as="h2" variant="headingMd">
          Stale Mapping Alerts
        </Text>
        <Card>
          <BlockStack gap="300">
            <Text as="p" variant="bodyMd">
              Alert after {staleDaysLabel} inactivity
            </Text>
            <Select
              label="Inactivity threshold"
              labelHidden
              options={STALE_MAPPING_DAY_OPTIONS}
              value={staleMappingDays}
              onChange={setStaleMappingDays}
            />
          </BlockStack>
        </Card>
      </BlockStack>
    </BlockStack>
  );
}
