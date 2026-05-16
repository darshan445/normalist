/** Shopify passes id_token on the embedded app URL on every Admin load. */
export function sessionTokenFromUrl() {
  if (typeof window === "undefined") return null;
  return new URLSearchParams(window.location.search).get("id_token");
}

/**
 * Session token for API calls. Uses URL id_token (embedded Admin).
 * App Bridge is not loaded here — dynamic injection sets async and breaks App Bridge.
 */
export async function fetchSessionToken() {
  return sessionTokenFromUrl();
}
