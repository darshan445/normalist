"use client";

import { Page, Card, Text, BlockStack } from "@shopify/polaris";

export default function Dashboard({ session }) {
  const merchant = session?.merchant;

  return (
    <Page title="Dashboard">
      <Card>
        <BlockStack gap="200">
          <Text as="h1" variant="headingLg">
            Hello World
          </Text>
          {merchant && (
            <Text as="p" variant="bodyMd" tone="subdued">
              Connected store: <strong>{merchant.name}</strong> ({merchant.platform_domain})
            </Text>
          )}
        </BlockStack>
      </Card>
    </Page>
  );
}
