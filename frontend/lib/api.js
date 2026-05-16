function apiBase() {
  if (typeof window !== "undefined") return "";
  return process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000";
}

async function fetchWithTimeout(url, options = {}, timeoutMs = 15000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } catch (error) {
    if (error.name === "AbortError") {
      throw new Error("API request timed out — is Rails running on port 3000?");
    }
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

export async function verifyShopifySession({ shop, sessionToken }) {
  const origin = typeof window !== "undefined" ? window.location.origin : undefined;
  const url = new URL(`${apiBase()}/api/v1/session`, origin);
  const headers = { Accept: "application/json" };

  if (sessionToken) {
    headers.Authorization = `Bearer ${sessionToken}`;
  } else if (process.env.NODE_ENV === "development" && shop) {
    url.searchParams.set("shop", shop);
  } else {
    return { ok: false, status: 0, data: null };
  }

  const response = await fetchWithTimeout(url.toString(), { headers, cache: "no-store" });

  let data = null;
  try {
    data = await response.json();
  } catch {
    data = null;
  }

  if (!response.ok) {
    return { ok: false, status: response.status, data };
  }

  return { ok: true, status: response.status, data };
}

export function shopifyLoginUrl({ shop, host }) {
  const base =
    typeof window !== "undefined"
      ? window.location.origin
      : process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000";

  const url = new URL("/login", base);
  if (shop) url.searchParams.set("shop", shop);
  if (host) url.searchParams.set("host", host);

  return url.toString();
}

export const API_URL = apiBase();
