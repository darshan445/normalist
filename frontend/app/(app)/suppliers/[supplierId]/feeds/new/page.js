import { redirect } from "next/navigation";

export default async function NewFeedRedirectPage({ params, searchParams }) {
  const { supplierId } = await params;
  const query = await searchParams;
  const qs = new URLSearchParams(query).toString();
  const path = `/suppliers/${supplierId}/feeds/new/file_upload${qs ? `?${qs}` : ""}`;

  redirect(path);
}
