export function shopifyNavHref(path, { shop, host, embedded }) {
  const href = path.startsWith("/") ? path : `/${path}`;
  const params = new URLSearchParams();

  if (shop) params.set("shop", shop);
  if (host) params.set("host", host);
  if (embedded) params.set("embedded", "1");

  const query = params.toString();
  return query ? `${href}?${query}` : href;
}
