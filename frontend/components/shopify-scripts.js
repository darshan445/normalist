import Script from "next/script";

/** Shopify API key + App Bridge for fresh session tokens (idToken) in embedded admin. */
export default function ShopifyScripts() {
  const apiKey = process.env.NEXT_PUBLIC_SHOPIFY_API_KEY;
  if (!apiKey) return null;

  return (
    <>
      <meta name="shopify-api-key" content={apiKey} />
      <Script
        src="https://cdn.shopify.com/shopifycloud/app-bridge.js"
        strategy="beforeInteractive"
      />
    </>
  );
}
