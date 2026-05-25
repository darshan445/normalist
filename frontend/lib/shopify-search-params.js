const STORAGE_KEYS = {
  shop: "normalist_shop",
  host: "normalist_host",
  embedded: "normalist_embedded",
};

function readUrlParams() {
  if (typeof window === "undefined") return null;
  return new URLSearchParams(window.location.search);
}

function persistParams({ shop, host, embedded }) {
  if (typeof window === "undefined") return;

  if (shop) sessionStorage.setItem(STORAGE_KEYS.shop, shop);
  if (host) sessionStorage.setItem(STORAGE_KEYS.host, host);
  if (embedded) sessionStorage.setItem(STORAGE_KEYS.embedded, "1");
}

function restoreFromStorage() {
  if (typeof window === "undefined") {
    return { shop: null, host: null, embedded: false };
  }

  return {
    shop: sessionStorage.getItem(STORAGE_KEYS.shop),
    host: sessionStorage.getItem(STORAGE_KEYS.host),
    embedded: sessionStorage.getItem(STORAGE_KEYS.embedded) === "1",
  };
}

export function pickShopifyParams(searchParams) {
  const urlParams = readUrlParams();

  let shop = searchParams?.get("shop") || urlParams?.get("shop") || null;
  let host = searchParams?.get("host") || urlParams?.get("host") || null;
  let embedded =
    searchParams?.get("embedded") === "1" || urlParams?.get("embedded") === "1";
  let idToken = searchParams?.get("id_token") || urlParams?.get("id_token") || null;

  const stored = restoreFromStorage();
  shop = shop || stored.shop;
  host = host || stored.host;
  if (!embedded) embedded = stored.embedded;

  persistParams({ shop, host, embedded });

  return { shop, host, embedded, idToken };
}

export function hasShopifyContext({ shop, host, embedded }) {
  // Embedded admin always sends shop + host; embedded=1 may be omitted after OAuth redirect.
  if (shop && host) return true;

  if (process.env.NODE_ENV === "development" && shop) return true;

  return false;
}
