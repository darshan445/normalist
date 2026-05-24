import { redirect } from "next/navigation";

export default async function PricingRedirectPage({ searchParams }) {
  const params = await searchParams;
  const qs = new URLSearchParams(params).toString();

  redirect(qs ? `/subscription?${qs}` : "/subscription");
}
