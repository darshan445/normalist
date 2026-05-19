export function shopifyNavHref(path, { shop, host, embedded, idToken }) {
  const href = path.startsWith("/") ? path : `/${path}`;
  const params = new URLSearchParams();

  if (shop) params.set("shop", shop);
  if (host) params.set("host", host);
  if (embedded) params.set("embedded", "1");
  if (idToken) params.set("id_token", idToken);

  const query = params.toString();
  return query ? `${href}?${query}` : href;
}
