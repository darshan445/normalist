import { cancelBillingSubscription } from "./api";

export async function cancelSubscription({ shop, sessionToken }) {
  const result = await cancelBillingSubscription({ shop, sessionToken });

  if (!result.ok) {
    const message =
      result.data?.message ||
      result.data?.error ||
      "Could not cancel subscription. Please try again.";
    throw new Error(message);
  }

  return result.data;
}
