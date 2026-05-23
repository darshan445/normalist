export function shopifyNavHref(path, { shop, host, embedded, idToken }) {
  const [rawPath, existingQuery = ""] = path.split("?", 2);
  const href = rawPath.startsWith("/") ? rawPath : `/${rawPath}`;
  const params = new URLSearchParams(existingQuery);

  if (shop) params.set("shop", shop);
  if (host) params.set("host", host);
  if (embedded) params.set("embedded", "1");
  if (idToken) params.set("id_token", idToken);

  const query = params.toString();
  return query ? `${href}?${query}` : href;
}
