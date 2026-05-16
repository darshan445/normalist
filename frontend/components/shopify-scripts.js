/** API key meta for Shopify embedded context. Auth uses id_token from the URL, not App Bridge. */
export default function ShopifyScripts() {
  const apiKey = process.env.NEXT_PUBLIC_SHOPIFY_API_KEY;
  if (!apiKey) return null;
  return <meta name="shopify-api-key" content={apiKey} />;
}
