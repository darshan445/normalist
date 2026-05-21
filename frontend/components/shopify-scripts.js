/**
 * App Bridge must be the first synchronous script from Shopify's CDN.
 * Do not use next/script — it injects async and App Bridge aborts.
 */
export default function ShopifyScripts() {
  const apiKey = process.env.NEXT_PUBLIC_SHOPIFY_API_KEY;
  if (!apiKey) return null;

  return (
    <>
      <meta name="shopify-api-key" content={apiKey} />
      {/* eslint-disable-next-line @next/next/no-sync-scripts */}
      <script src="https://cdn.shopify.com/shopifycloud/app-bridge.js" />
    </>
  );
}
