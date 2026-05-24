"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { BlockStack, Spinner } from "@shopify/polaris";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { fetchFeed } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import FeedFileUploadShow from "./feed-file-upload-show";
import FeedGoogleSheetsShow from "./feed-google-sheets-show";

export default function FeedShow({ supplierId, feedId }) {
  const [feedType, setFeedType] = useState(null);
  const searchParams = useSearchParams();
  const { shop } = pickShopifyParams(searchParams);

  useEffect(() => {
    let cancelled = false;

    async function detectType() {
      const sessionToken = await fetchSessionToken();
      const result = await fetchFeed(supplierId, feedId, { shop, sessionToken });
      if (!cancelled && result.ok) {
        setFeedType(result.data?.feed?.feed_type ?? null);
      } else if (!cancelled) {
        setFeedType("unknown");
      }
    }

    detectType();
    return () => {
      cancelled = true;
    };
  }, [supplierId, feedId, shop]);

  if (!feedType) {
    return (
      <BlockStack gap="300" inlineAlign="center">
        <Spinner accessibilityLabel="Loading feed" />
      </BlockStack>
    );
  }

  if (feedType === "file_upload") {
    return <FeedFileUploadShow supplierId={supplierId} feedId={feedId} />;
  }

  return <FeedGoogleSheetsShow supplierId={supplierId} feedId={feedId} />;
}
