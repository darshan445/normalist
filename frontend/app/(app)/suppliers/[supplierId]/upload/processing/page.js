import { redirect } from "next/navigation";

export default async function SupplierProcessingRedirectPage({ params, searchParams }) {
  const { supplierId } = await params;
  const query = await searchParams;
  const sp = new URLSearchParams(query);
  const hash = "#processing";
  const qs = sp.toString();
  const path = `/suppliers/${supplierId}${qs ? `?${qs}` : ""}${hash}`;

  redirect(path);
}
