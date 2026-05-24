import { openTopLevel } from "./open-top-level";

export function shopifyBillingSettingsUrl(shopDomain) {
  if (!shopDomain) return null;

  const shop = shopDomain.includes(".myshopify.com")
    ? shopDomain
    : `${shopDomain}.myshopify.com`;

  return `https://${shop}/admin/settings/billing`;
}

export function openShopifyBilling(shopDomain) {
  const url = shopifyBillingSettingsUrl(shopDomain);
  if (url) openTopLevel(url);
}
