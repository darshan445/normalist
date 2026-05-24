"use client";

import { useState } from "react";
import { useSearchParams } from "next/navigation";
import { Button } from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { fetchSessionToken } from "../lib/shopify-session-token";
import { startSubscription } from "../lib/start-subscription";

export default function SubscribeButton({ children, onError, ...buttonProps }) {
  const searchParams = useSearchParams();
  const shopifyParams = pickShopifyParams(searchParams);
  const [loading, setLoading] = useState(false);

  const handleClick = async () => {
    setLoading(true);
    onError?.(null);

    try {
      const sessionToken = await fetchSessionToken();
      await startSubscription({
        shop: shopifyParams.shop,
        sessionToken,
      });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Could not start subscription.";
      onError?.(message);
      setLoading(false);
    }
  };

  return (
    <Button
      variant="primary"
      loading={loading}
      onClick={handleClick}
      {...buttonProps}
    >
      {children}
    </Button>
  );
}
