"use client";

import { Text, Card, BlockStack } from "@shopify/polaris";

export default function PlaceholderPage({ title, description }) {
  return (
    <BlockStack gap="400">
      <Text as="h1" variant="headingLg">
        {title}
      </Text>
      <Card>
        <BlockStack gap="200">
          <Text as="p" variant="bodyMd" tone="subdued">
            {description}
          </Text>
        </BlockStack>
      </Card>
    </BlockStack>
  );
}
