"use client";

import { Suspense } from "react";
import { useSearchParams } from "next/navigation";
import { Spinner, Page, Card, BlockStack } from "@shopify/polaris";
import RequireShopifyAuth from "./require-shopify-auth";
import AppShell from "./app-shell";
import { SessionProvider } from "../lib/session-context";
import { TrialStatusProvider } from "../lib/trial-status-context";
import { pickShopifyParams } from "../lib/shopify-search-params";

function AuthenticatedAppInner({ children }) {
  const searchParams = useSearchParams();
  const { shop, host, embedded } = pickShopifyParams(searchParams);

  return (
    <RequireShopifyAuth shop={shop} host={host} embedded={embedded}>
      {({ session }) => (
        <SessionProvider session={session}>
          <TrialStatusProvider>
            <AppShell>{children}</AppShell>
          </TrialStatusProvider>
        </SessionProvider>
      )}
    </RequireShopifyAuth>
  );
}

function LoadingFallback() {
  return (
    <Page title="NormaList">
      <Card>
        <BlockStack gap="300" inlineAlign="center">
          <Spinner accessibilityLabel="Loading" size="large" />
        </BlockStack>
      </Card>
    </Page>
  );
}

export default function AuthenticatedApp({ children }) {
  return (
    <Suspense fallback={<LoadingFallback />}>
      <AuthenticatedAppInner>{children}</AuthenticatedAppInner>
    </Suspense>
  );
}
