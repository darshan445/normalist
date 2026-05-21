import { pickShopifyParams } from "./shopify-search-params";

/** Shopify passes id_token on the embedded app URL on initial Admin load only. */
export function sessionTokenFromUrl() {
  if (typeof window === "undefined") return null;
  return new URLSearchParams(window.location.search).get("id_token");
}

function embeddedShopifyContext() {
  const { host, embedded } = pickShopifyParams();
  return Boolean(host || embedded);
}

function waitForAppBridge(maxMs = 8000) {
  return new Promise((resolve, reject) => {
    if (typeof window === "undefined") {
      reject(new Error("no window"));
      return;
    }

    const ready = () => window.shopify?.idToken;
    if (ready()) {
      resolve(window.shopify);
      return;
    }

    const started = Date.now();
    const tick = () => {
      if (ready()) {
        resolve(window.shopify);
        return;
      }
      if (Date.now() - started > maxMs) {
        reject(new Error("App Bridge not loaded"));
        return;
      }
      requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  });
}

/**
 * Session token for API calls. In embedded admin, always request a fresh token
 * from App Bridge (JWT expires in ~1 minute). Do not cache in sessionStorage.
 */
export async function fetchSessionToken() {
  if (typeof window === "undefined") return null;

  if (embeddedShopifyContext()) {
    try {
      const shopify = await waitForAppBridge();
      return await shopify.idToken();
    } catch {
      return sessionTokenFromUrl();
    }
  }

  return sessionTokenFromUrl();
}
