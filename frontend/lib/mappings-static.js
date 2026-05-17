/** Pending codes per supplier (static demo data). */
export const PENDING_MAPPINGS_BY_SUPPLIER = {
  "supplier-a": [
    { id: "xyz-9982", code: "XYZ-9982", quantity: 45 },
    { id: "foo-001", code: "FOO-001", quantity: 12 },
    { id: "bar-x99", code: "BAR-X99", quantity: 8 },
  ],
  "supplier-b": [],
  "supplier-c": [],
};

export const VARIANT_SEARCH_OPTIONS = [
  { label: "Search your variants…", value: "" },
  { label: "AERO-BLK-09 — Air Runner / Black Size 9", value: "AERO-BLK-09" },
  { label: "FOAM-GRY-09 — FoamStep / Grey Size 9", value: "FOAM-GRY-09" },
  { label: "SOCK-WHT-OS — Running Socks / Default", value: "SOCK-WHT-OS" },
];

export function pendingMappingsForSupplier(supplierId) {
  return PENDING_MAPPINGS_BY_SUPPLIER[supplierId] || [];
}
