"use client";

import { useState } from "react";
import { useSearchParams } from "next/navigation";
import {
  Page,
  Card,
  BlockStack,
  InlineStack,
  Text,
  Badge,
  Button,
  List,
  Banner,
  Divider,
  Spinner,
} from "@shopify/polaris";
import { useTrialStatus } from "../lib/trial-status-context";
import { useAppSession } from "../lib/session-context";
import { pickShopifyParams } from "../lib/shopify-search-params";
import {
  subscribeButtonLabel,
  formatMonthlyPrice,
  DEFAULT_MONTHLY_PRICE,
} from "../lib/billing-href";
import { formatBillingDate } from "../lib/format-billing-date";
import { openShopifyBilling } from "../lib/open-shopify-billing";
import SubscribeButton from "./subscribe-button";
import CancelSubscriptionButton from "./cancel-subscription-button";

const INCLUDED_FEATURES = [
  "Unlimited suppliers",
  "Unlimited variants",
  "Unlimited file uploads",
  "AI column detection",
  "Automatic code mapping",
  "Shopify inventory sync",
  "Real-time catalog sync",
];

function statusPresentation(trialStatus) {
  if (trialStatus.cancellation_pending) {
    return {
      badge: { tone: "warning", label: "Cancelling" },
      summary: `Your subscription is cancelled and will not renew. You keep access until ${formatBillingDate(trialStatus.access_until)}.`,
    };
  }

  if (trialStatus.plan_status === "cancelled") {
    return {
      badge: { tone: "attention", label: "Cancelled" },
      summary: "Your subscription has ended. Subscribe again to restore access.",
    };
  }

  if (trialStatus.subscribed) {
    return {
      badge: { tone: "success", label: "Active" },
      summary: "Your NormaList subscription is active.",
    };
  }

  if (trialStatus.plan_status === "frozen") {
    return {
      badge: { tone: "critical", label: "Payment failed" },
      summary: "Your last payment failed. Update billing in Shopify to restore access.",
    };
  }

  if (trialStatus.trial_expired) {
    return {
      badge: { tone: "critical", label: "Trial expired" },
      summary: "Your free trial has ended. Subscribe to continue using NormaList.",
    };
  }

  if (trialStatus.trial_ending_soon) {
    return {
      badge: { tone: "warning", label: "Trial ending soon" },
      summary: `${trialStatus.trial_days_remaining} day${
        trialStatus.trial_days_remaining === 1 ? "" : "s"
      } left on your free trial.`,
    };
  }

  if (trialStatus.trialing) {
    return {
      badge: { tone: "info", label: "Free trial" },
      summary: `${trialStatus.trial_days_remaining} days remaining on your free trial.`,
    };
  }

  return {
    badge: { tone: "attention", label: "Not subscribed" },
    summary: "Choose a plan to get started with NormaList.",
  };
}

export default function SubscriptionBilling() {
  const searchParams = useSearchParams();
  const shopifyParams = pickShopifyParams(searchParams);
  const session = useAppSession();
  const { trialStatus, loadState } = useTrialStatus();
  const [subscribeError, setSubscribeError] = useState(null);
  const [cancelError, setCancelError] = useState(null);
  const [cancelSuccess, setCancelSuccess] = useState(false);

  const billingError = searchParams.get("billing_error") || subscribeError || cancelError;
  const monthlyPrice = trialStatus?.price ?? DEFAULT_MONTHLY_PRICE;
  const subscribeLabel = subscribeButtonLabel(monthlyPrice);
  const shopDomain = session?.merchant?.platform_domain || shopifyParams.shop;

  const hasPaidAccess = Boolean(trialStatus?.subscribed);
  const cancellationPending = Boolean(trialStatus?.cancellation_pending);
  const canCancel = Boolean(trialStatus?.can_cancel);
  const accessUntil = trialStatus?.access_until || trialStatus?.billing_on;

  const needsSubscribe =
    trialStatus &&
    !hasPaidAccess &&
    (trialStatus.trial_expired ||
      trialStatus.plan_status === "frozen" ||
      trialStatus.plan_status === "cancelled" ||
      trialStatus.trial_ending_soon ||
      trialStatus.trialing);

  if (loadState.status === "loading" && !trialStatus) {
    return (
      <Page title="Subscription & billing">
        <Card>
          <BlockStack gap="200" inlineAlign="center">
            <Spinner accessibilityLabel="Loading subscription" size="small" />
          </BlockStack>
        </Card>
      </Page>
    );
  }

  if (loadState.status === "error") {
    return (
      <Page title="Subscription & billing">
        <Banner tone="critical">
          <p>{loadState.error}</p>
        </Banner>
      </Page>
    );
  }

  const presentation = trialStatus ? statusPresentation(trialStatus) : null;

  return (
    <Page title="Subscription & billing">
      <BlockStack gap="500">
        {billingError ? (
          <Banner tone="critical" title="Could not update subscription">
            <p>{billingError}</p>
          </Banner>
        ) : null}

        {cancelSuccess ? (
          <Banner tone="success" title="Subscription cancelled">
            <p>
              Your subscription will not renew. You keep full access until{" "}
              {formatBillingDate(accessUntil)}.
            </p>
          </Banner>
        ) : null}

        {presentation ? (
          <Card>
            <BlockStack gap="300">
              <InlineStack align="space-between" blockAlign="center">
                <Text as="h2" variant="headingMd">
                  Current status
                </Text>
                <Badge tone={presentation.badge.tone}>{presentation.badge.label}</Badge>
              </InlineStack>
              <Text as="p" variant="bodyMd">
                {presentation.summary}
              </Text>
            </BlockStack>
          </Card>
        ) : null}

        <Card>
          <BlockStack gap="500">
            <BlockStack gap="200">
              <Text as="h2" variant="headingMd">
                NormaList
              </Text>
              <Text as="p" variant="headingXl">
                {formatMonthlyPrice(monthlyPrice)} / month
              </Text>
              <Text as="p" variant="bodyMd" tone="subdued">
                Everything included. No hidden fees. Cancel anytime.
              </Text>
            </BlockStack>

            <Divider />

            <BlockStack gap="200">
              <Text as="h3" variant="headingSm">
                What&apos;s included
              </Text>
              <List type="bullet">
                {INCLUDED_FEATURES.map((feature) => (
                  <List.Item key={feature}>{feature}</List.Item>
                ))}
              </List>
            </BlockStack>

            {hasPaidAccess ? (
              <>
                <Divider />
                <BlockStack gap="200">
                  <Text as="h3" variant="headingSm">
                    Billing
                  </Text>
                  {cancellationPending ? (
                    <>
                      <Text as="p" variant="bodyMd">
                        Access until: {formatBillingDate(accessUntil)}
                      </Text>
                      <Text as="p" variant="bodySm" tone="subdued">
                        Your subscription is cancelled and will not auto-renew.
                      </Text>
                    </>
                  ) : (
                    <>
                      <Text as="p" variant="bodyMd">
                        Next billing date: {formatBillingDate(trialStatus.billing_on)}
                      </Text>
                      <Text as="p" variant="bodySm" tone="subdued">
                        Invoices and payment methods are managed in your Shopify admin.
                      </Text>
                    </>
                  )}
                </BlockStack>
              </>
            ) : null}

            <BlockStack gap="200">
              {needsSubscribe ? (
                <>
                  <SubscribeButton size="large" onError={setSubscribeError}>
                    {trialStatus.plan_status === "frozen"
                      ? "Retry payment"
                      : subscribeLabel}
                  </SubscribeButton>
                  <Text as="p" variant="bodySm" tone="subdued">
                    You will be redirected to Shopify to confirm your subscription.
                  </Text>
                </>
              ) : null}

              {hasPaidAccess ? (
                <BlockStack gap="200">
                  <Button onClick={() => openShopifyBilling(shopDomain)}>
                    Manage billing in Shopify
                  </Button>
                  {canCancel ? (
                    <CancelSubscriptionButton
                      accessUntil={accessUntil}
                      onError={(message) => {
                        setCancelSuccess(false);
                        setCancelError(message);
                      }}
                      onSuccess={() => {
                        setCancelError(null);
                        setCancelSuccess(true);
                      }}
                    />
                  ) : null}
                </BlockStack>
              ) : null}
            </BlockStack>
          </BlockStack>
        </Card>
      </BlockStack>
    </Page>
  );
}
