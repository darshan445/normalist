"use client";

import { useEffect, useState } from "react";
import { Card, Page, Spinner, Text, BlockStack, Banner } from "@shopify/polaris";
import { verifyShopifySession, shopifyLoginUrl } from "../lib/api";
import { fetchSessionToken } from "../lib/shopify-session-token";
import { hasShopifyContext } from "../lib/shopify-search-params";

const REDIRECT_KEY = "normalist_oauth_redirect";

export default function RequireShopifyAuth({ shop, host, embedded, children }) {
  const [state, setState] = useState({ status: "loading", session: null, error: null });

  useEffect(() => {
    let cancelled = false;

    async function authenticate() {
      if (!hasShopifyContext({ shop, host, embedded })) {
        setState({
          status: "denied",
          session: null,
          error: "missing_context",
        });
        return;
      }

      try {
        const sessionToken = embedded ? await fetchSessionToken() : null;
        const result = await verifyShopifySession({ shop, sessionToken });

        if (cancelled) return;

        if (result.ok && result.data) {
          sessionStorage.removeItem(REDIRECT_KEY);
          setState({ status: "authenticated", session: result.data, error: null });
          return;
        }

        const needsInstall =
          result.status === 401 &&
          (result.data?.error === "shop_not_installed" || result.data?.error === "unauthorized");

        if (needsInstall) {
          const alreadyTried = sessionStorage.getItem(REDIRECT_KEY) === "1";

          if (!alreadyTried && typeof window !== "undefined") {
            sessionStorage.setItem(REDIRECT_KEY, "1");
            window.location.assign(shopifyLoginUrl({ shop, host }));
            setState({ status: "redirecting", session: null, error: null });
            return;
          }

          setState({
            status: "denied",
            session: null,
            error:
              "App install did not finish on the server. Open OAuth login once, approve the app, then reload from Shopify Admin.",
          });
          return;
        }

        setState({
          status: "denied",
          session: null,
          error: result.data?.message || "Could not verify your store session.",
        });
      } catch (error) {
        if (cancelled) return;
        setState({ status: "denied", session: null, error: error.message });
      }
    }

    authenticate();

    return () => {
      cancelled = true;
    };
  }, [shop, host, embedded]);

  if (state.status === "loading" || state.status === "redirecting") {
    return (
      <Page title="NormaList">
        <Card>
          <BlockStack gap="300" inlineAlign="center">
            <Spinner accessibilityLabel="Loading" size="large" />
            <Text as="p" variant="bodyMd" tone="subdued">
              {state.status === "redirecting"
                ? "Redirecting to Shopify install…"
                : "Verifying your store session…"}
            </Text>
            {state.status === "redirecting" && shop && (
              <Text as="p" variant="bodySm" tone="subdued">
                <a href={shopifyLoginUrl({ shop, host })}>Continue OAuth install</a>
              </Text>
            )}
          </BlockStack>
        </Card>
      </Page>
    );
  }

  if (state.status === "denied") {
    const devHint =
      process.env.NODE_ENV === "development"
        ? " Complete install: open the OAuth login link below, approve the app, then reload from Shopify Admin."
        : "";

    return (
      <Page title="NormaList">
        <Card>
          <BlockStack gap="300">
            <Banner tone="warning" title="Authentication required">
              <p>
                Open this app from Shopify Admin after installing it for your store.
                {devHint}
              </p>
              {shop && (
                <p>
                  <a href={shopifyLoginUrl({ shop, host })}>Install / reconnect OAuth</a>
                </p>
              )}
            </Banner>
            {state.error && state.error !== "missing_context" && (
              <Text as="p" variant="bodyMd" tone="critical">
                {state.error}
              </Text>
            )}
          </BlockStack>
        </Card>
      </Page>
    );
  }

  return children({ session: state.session });
}
