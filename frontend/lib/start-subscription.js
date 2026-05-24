import { apiPost } from "./api";
import { openTopLevel } from "./open-top-level";

export async function startSubscription({ shop, sessionToken }) {
  const result = await apiPost("/api/v1/billing", { shop, sessionToken });

  if (!result.ok) {
    const message =
      result.data?.message ||
      result.data?.error ||
      "Could not start subscription. Please try again.";
    throw new Error(message);
  }

  const confirmationUrl = result.data?.confirmation_url;
  if (!confirmationUrl) {
    throw new Error("Shopify did not return a confirmation URL.");
  }

  openTopLevel(confirmationUrl);
}
