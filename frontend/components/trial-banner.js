"use client";

import { useSearchParams } from "next/navigation";
import { Banner } from "@shopify/polaris";
import { useTrialStatus } from "../lib/trial-status-context";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { pricingHref } from "../lib/billing-href";

export default function TrialBanner() {
  const searchParams = useSearchParams();
  const shopifyParams = pickShopifyParams(searchParams);
  const { trialStatus, loadState } = useTrialStatus();

  if (loadState.status !== "ready" || !trialStatus) return null;

  const pricingUrl = pricingHref(shopifyParams);

  if (trialStatus.trial_expired) {
    return (
      <Banner
        title="Your trial has ended"
        tone="critical"
        action={{ content: "Subscribe Now", url: pricingUrl }}
      >
        <p>Subscribe to continue using NormaList.</p>
      </Banner>
    );
  }

  if (trialStatus.trial_ending_soon) {
    return (
      <Banner
        title="Your trial ends soon"
        tone="warning"
        action={{ content: "Subscribe Now", url: pricingUrl }}
      >
        <p>
          {trialStatus.trial_days_remaining} day
          {trialStatus.trial_days_remaining === 1 ? "" : "s"} remaining on your free
          trial. Subscribe to keep access after your trial ends.
        </p>
      </Banner>
    );
  }

  return null;
}
