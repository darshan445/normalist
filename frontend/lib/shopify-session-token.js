const STORAGE_KEY = "normalist_shopify_id_token";

/** Shopify passes id_token on the embedded app URL on every Admin load. */
export function sessionTokenFromUrl() {
  if (typeof window === "undefined") return null;
  return new URLSearchParams(window.location.search).get("id_token");
}

function persistSessionToken(token) {
  if (typeof window === "undefined" || !token) return;
  sessionStorage.setItem(STORAGE_KEY, token);
}

function sessionTokenFromStorage() {
  if (typeof window === "undefined") return null;
  return sessionStorage.getItem(STORAGE_KEY);
}

/**
 * Session token for API calls. Prefer fresh id_token from URL; keep last token
 * in sessionStorage so client-side nav (e.g. /suppliers) still authenticates.
 */
export async function fetchSessionToken() {
  const fromUrl = sessionTokenFromUrl();
  if (fromUrl) {
    persistSessionToken(fromUrl);
    return fromUrl;
  }
  return sessionTokenFromStorage();
}
