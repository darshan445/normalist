import { redirect } from "next/navigation";

export default async function NewFeedRedirectPage({ params, searchParams }) {
  const { supplierId } = await params;
  const query = await searchParams;
  const qs = new URLSearchParams({ ...query, type: "file_upload" }).toString();

  redirect(`/suppliers/${supplierId}/feeds/setup?${qs}`);
}
