export function pickShopifyParams(searchParams) {
  const shop = searchParams?.get("shop") || null;
  const host = searchParams?.get("host") || null;
  const embedded = searchParams?.get("embedded") === "1";
  const idToken = searchParams?.get("id_token") || null;

  return { shop, host, embedded, idToken };
}

export function hasShopifyContext({ shop, host, embedded }) {
  if (embedded && shop && host) return true;

  if (process.env.NODE_ENV === "development" && shop) return true;

  return false;
}
