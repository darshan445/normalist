/**
 * Break out of the embedded app iframe (required for Shopify billing confirmation).
 * @see https://shopify.dev/docs/api/app-bridge-library/apis/navigation
 */
export function openTopLevel(url) {
  if (typeof window === "undefined" || !url) return;

  if (typeof window.open === "function") {
    window.open(url, "_top");
    return;
  }

  window.top.location.href = url;
}
