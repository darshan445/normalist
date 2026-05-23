import { redirect } from "next/navigation";

export default async function LegacyGoogleSheetsFeedPage({ params, searchParams }) {
  const { supplierId } = await params;
  const query = await searchParams;
  const qs = new URLSearchParams({ ...query, type: "google_sheets" }).toString();

  redirect(`/suppliers/${supplierId}/feeds/setup?${qs}`);
}
