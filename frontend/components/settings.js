"use client";

import { useSearchParams } from "next/navigation";
import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Badge,
  Button,
} from "@shopify/polaris";
import { useAppSession } from "../lib/session-context";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { subscriptionHref } from "../lib/billing-href";

export default function Settings() {
  const searchParams = useSearchParams();
  const shopifyParams = pickShopifyParams(searchParams);
  const session = useAppSession();

  const storeDomain =
    session?.merchant?.platform_domain || "your-store.myshopify.com";
  const manageSubscriptionUrl = subscriptionHref(shopifyParams);

  return (
    <BlockStack gap="500">
      <Text as="h1" variant="headingLg">
        Settings
      </Text>

      <BlockStack gap="300">
        <Text as="h2" variant="headingMd">
          Subscription
        </Text>
        <Card>
          <BlockStack gap="300">
            <Text as="p" variant="bodyMd" tone="subdued">
              View your plan, billing details, and subscription options.
            </Text>
            <div>
              <Button url={manageSubscriptionUrl}>Manage subscription</Button>
            </div>
          </BlockStack>
        </Card>
      </BlockStack>

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
