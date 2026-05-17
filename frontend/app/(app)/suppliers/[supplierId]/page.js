import { notFound } from "next/navigation";
import SupplierDetail from "../../../../components/supplier-detail";
import { findStaticSupplier } from "../../../../lib/suppliers-static";

export default async function SupplierDetailPage({ params }) {
  const { supplierId } = await params;
  const supplier = findStaticSupplier(supplierId);

  if (!supplier) {
    notFound();
  }

  return <SupplierDetail supplier={supplier} />;
}
