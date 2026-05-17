import { redirect } from "next/navigation";

export default async function SupplierUploadRedirectPage({ params, searchParams }) {
  const { supplierId } = await params;
  const query = await searchParams;
  const qs = new URLSearchParams(query).toString();
  const path = `/suppliers/${supplierId}${qs ? `?${qs}` : ""}`;

  redirect(path);
}
