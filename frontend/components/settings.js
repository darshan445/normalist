"use client";

import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Badge,
} from "@shopify/polaris";
import { useAppSession } from "../lib/session-context";
import SubscriptionSection from "./subscription-section";

export default function Settings() {
  const session = useAppSession();

  const storeDomain =
    session?.merchant?.platform_domain || "your-store.myshopify.com";

  return (
    <BlockStack gap="500">
      <Text as="h1" variant="headingLg">
        Settings
      </Text>

      <SubscriptionSection />

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
            <Text as="p" variant="bodyMd">
              Store: {storeDomain}
            </Text>
          </BlockStack>
        </Card>
      </BlockStack>
    </BlockStack>
  );
}
