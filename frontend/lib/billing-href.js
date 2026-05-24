import { shopifyNavHref } from "./shopify-nav-href";

export const DEFAULT_MONTHLY_PRICE = 14;

export function formatMonthlyPrice(price) {
  const amount = price ?? DEFAULT_MONTHLY_PRICE;
  return `$${Number(amount).toFixed(Number(amount) % 1 === 0 ? 0 : 2)}`;
}

export function billingHref(shopifyParams) {
  return shopifyNavHref("/billing", shopifyParams);
}

export function pricingHref(shopifyParams) {
  return shopifyNavHref("/pricing", shopifyParams);
}

export function subscribeButtonLabel(price) {
  return `Subscribe Now — ${formatMonthlyPrice(price)}/month`;
}
