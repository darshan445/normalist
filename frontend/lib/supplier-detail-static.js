export const DEFAULT_FEEDS = [
  {
    id: "file-upload",
    icon: "📁",
    name: "File Upload",
    status: "active",
    lastUpload: "2hrs ago",
    syncedCount: 45,
    pendingCount: 3,
    uploadEnabled: true,
  },
  {
    id: "google-sheets",
    icon: "🔗",
    name: "Google Sheets",
    status: "coming_soon",
    uploadEnabled: false,
  },
];

export const DEFAULT_COLUMN_PROFILE = {
  skuColumn: "ItemCode_Ref",
  quantityColumn: "Avail_Qty",
  source: "Auto-detected by AI",
};

export const ACTIVE_MAPPINGS_BY_SUPPLIER = {
  "supplier-a": [
    { supplierCode: "XYZ-9981", masterSku: "AERO-BLK-09", status: "active" },
    { supplierCode: "XYZ-9980", masterSku: "AERO-WHT-10", status: "active" },
    { supplierCode: "FOA-001", masterSku: "FOAM-GRY-09", status: "active" },
    { supplierCode: "SKP-774", masterSku: null, status: "skipped" },
  ],
  "supplier-b": [
    { supplierCode: "ABC-100", masterSku: "AERO-BLK-09", status: "active" },
    { supplierCode: "ABC-101", masterSku: "FOAM-GRY-09", status: "active" },
  ],
  "supplier-c": [
    { supplierCode: "CAT-01", masterSku: "SOCK-WHT-OS", status: "active" },
  ],
};

export function supplierDetailData(supplier) {
  const feeds = DEFAULT_FEEDS.map((feed) => ({
    ...feed,
    syncedCount: feed.syncedCount ?? supplier.mappedCount,
    pendingCount: feed.pendingCount ?? supplier.pendingCount,
  }));

  return {
    feeds,
    columnProfile: DEFAULT_COLUMN_PROFILE,
    activeMappings: ACTIVE_MAPPINGS_BY_SUPPLIER[supplier.id] || [],
    activeMappingTotal: supplier.mappedCount,
  };
}
