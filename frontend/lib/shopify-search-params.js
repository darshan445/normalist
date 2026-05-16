export function pickShopifyParams(searchParams) {
  const shop = searchParams?.get("shop") || null;
  const host = searchParams?.get("host") || null;
  const embedded = searchParams?.get("embedded") === "1";

  return { shop, host, embedded };
}

export function hasShopifyContext({ shop, host, embedded }) {
  if (embedded && shop && host) return true;

  if (process.env.NODE_ENV === "development" && shop) return true;

  return false;
}
