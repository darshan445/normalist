"use client";

import {
  Text,
  Card,
  BlockStack,
  Badge,
  Spinner,
  Banner,
} from "@shopify/polaris";
import { useTrialStatus } from "../lib/trial-status-context";
import { subscribeButtonLabel, formatMonthlyPrice } from "../lib/billing-href";
import SubscribeButton from "./subscribe-button";
import { formatBillingDate } from "../lib/format-billing-date";

export default function SubscriptionSection() {
  const { trialStatus, loadState } = useTrialStatus();

  const monthlyPrice = trialStatus?.price ?? 14;
  const subscribeLabel = subscribeButtonLabel(monthlyPrice);

  if (loadState.status === "loading" && !trialStatus) {
    return (
      <BlockStack gap="300">
        <Text as="h2" variant="headingMd">
          Subscription
        </Text>
        <Card>
          <BlockStack gap="200" inlineAlign="center">
            <Spinner accessibilityLabel="Loading subscription status" size="small" />
          </BlockStack>
        </Card>
      </BlockStack>
    );
  }

  if (loadState.status === "error") {
    return (
      <BlockStack gap="300">
        <Text as="h2" variant="headingMd">
          Subscription
        </Text>
        <Banner tone="critical">
          <p>{loadState.error}</p>
        </Banner>
      </BlockStack>
    );
  }

  if (!trialStatus) return null;

  let card = null;

  if (trialStatus.subscribed || trialStatus.plan_status === "active") {
    card = (
      <Card>
        <BlockStack gap="300">
          <Badge tone="success">Active</Badge>
          <Text as="p" variant="bodyMd">
            NormaList — {formatMonthlyPrice(monthlyPrice)}/month
          </Text>
          <Text as="p" variant="bodySm" tone="subdued">
            Next billing: {formatBillingDate(trialStatus.billing_on)}
          </Text>
        </BlockStack>
      </Card>
    );
  } else if (trialStatus.plan_status === "frozen") {
    card = (
      <Card>
        <BlockStack gap="300">
          <Badge tone="critical">Payment Failed</Badge>
          <Text as="p" variant="bodyMd">
            Your payment failed.
          </Text>
          <Text as="p" variant="bodyMd">
            Please update your payment details in Shopify.
          </Text>
          <div>
            <SubscribeButton>Retry Payment</SubscribeButton>
          </div>
        </BlockStack>
      </Card>
    );
  } else if (trialStatus.trial_expired) {
    card = (
      <Card>
        <BlockStack gap="300">
          <Badge tone="critical">Trial Expired</Badge>
          <Text as="p" variant="bodyMd">
            Your free trial has ended.
          </Text>
          <Text as="p" variant="bodyMd">
            Subscribe to continue using NormaList.
          </Text>
          <div>
            <SubscribeButton>{subscribeLabel}</SubscribeButton>
          </div>
        </BlockStack>
      </Card>
    );
  } else if (trialStatus.trial_ending_soon) {
    card = (
      <Card>
        <BlockStack gap="300">
          <Badge tone="warning">Trial Ending Soon</Badge>
          <Text as="p" variant="bodyMd">
            Only {trialStatus.trial_days_remaining} day
            {trialStatus.trial_days_remaining === 1 ? "" : "s"} left
          </Text>
          <div>
            <SubscribeButton>{subscribeLabel}</SubscribeButton>
          </div>
        </BlockStack>
      </Card>
    );
  } else if (trialStatus.trialing && trialStatus.trial_days_remaining > 3) {
    card = (
      <Card>
        <BlockStack gap="300">
          <Badge tone="info">Free Trial</Badge>
          <Text as="p" variant="bodyMd">
            {trialStatus.trial_days_remaining} days remaining
          </Text>
          <Text as="p" variant="bodyMd">
            Subscribe before your trial ends to keep access.
          </Text>
          <div>
            <SubscribeButton>{subscribeLabel}</SubscribeButton>
          </div>
        </BlockStack>
      </Card>
    );
  }

  if (!card) return null;

  return (
    <BlockStack gap="300">
      <Text as="h2" variant="headingMd">
        Subscription
      </Text>
      {card}
    </BlockStack>
  );
}
