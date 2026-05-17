export const STATIC_SUPPLIERS = [
  {
    id: "supplier-a",
    name: "Supplier A",
    mappedCount: 45,
    pendingCount: 3,
    status: "warning",
  },
  {
    id: "supplier-b",
    name: "Supplier B",
    mappedCount: 30,
    pendingCount: 0,
    status: "ok",
  },
  {
    id: "supplier-c",
    name: "Supplier C",
    mappedCount: 12,
    pendingCount: 0,
    status: "ok",
  },
];

export function findStaticSupplier(supplierId) {
  return STATIC_SUPPLIERS.find((supplier) => supplier.id === supplierId);
}

export const STATIC_PREVIOUS_UPLOADS = [
  { date: "12 May", ready: 45, pending: 2 },
  { date: "08 May", ready: 43, pending: 0 },
];
