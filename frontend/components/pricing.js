"use client";

import { useState } from "react";
import { useSearchParams } from "next/navigation";
import {
  Page,
  Card,
  BlockStack,
  Text,
  List,
  Banner,
} from "@shopify/polaris";
import {
  subscribeButtonLabel,
  formatMonthlyPrice,
  DEFAULT_MONTHLY_PRICE,
} from "../lib/billing-href";
import { useTrialStatus } from "../lib/trial-status-context";
import SubscribeButton from "./subscribe-button";

const INCLUDED_FEATURES = [
  "Unlimited suppliers",
  "Unlimited variants",
  "Unlimited file uploads",
  "AI column detection",
  "Automatic code mapping",
  "Shopify inventory sync",
  "Real-time catalog sync",
];

export default function Pricing() {
  const searchParams = useSearchParams();
  const { trialStatus } = useTrialStatus();
  const [subscribeError, setSubscribeError] = useState(null);

  const monthlyPrice = trialStatus?.price ?? DEFAULT_MONTHLY_PRICE;
  const billingError = searchParams.get("billing_error") || subscribeError;

  return (
    <Page title="Subscribe to NormaList">
      {billingError ? (
        <Banner tone="critical" title="Could not start subscription">
          <p>{billingError}</p>
        </Banner>
      ) : null}
      <Card>
        <BlockStack gap="500">
          <BlockStack gap="200">
            <Text as="p" variant="headingXl">
              {formatMonthlyPrice(monthlyPrice)} / month
            </Text>
            <Text as="p" variant="bodyMd" tone="subdued">
              Everything included. No hidden fees. Cancel anytime.
            </Text>
          </BlockStack>

          <BlockStack gap="200">
            <Text as="h2" variant="headingSm">
              What&apos;s included
            </Text>
            <List type="bullet">
              {INCLUDED_FEATURES.map((feature) => (
                <List.Item key={feature}>{feature}</List.Item>
              ))}
            </List>
          </BlockStack>

          <BlockStack gap="200">
            <SubscribeButton size="large" onError={setSubscribeError}>
              {subscribeButtonLabel(monthlyPrice)}
            </SubscribeButton>
            <Text as="p" variant="bodySm" tone="subdued">
              You will be redirected to Shopify to confirm your subscription.
            </Text>
          </BlockStack>
        </BlockStack>
      </Card>
    </Page>
  );
}
