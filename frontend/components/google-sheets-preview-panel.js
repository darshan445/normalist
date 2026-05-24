"use client";

import {
  Text,
  Card,
  BlockStack,
  InlineStack,
  Badge,
  DataTable,
  Spinner,
} from "@shopify/polaris";

function cleanColumnName(header) {
  return String(header).replace(/\s*\(Column [A-Z]+\)\s*$/i, "").trim();
}

export function previewFromSupplierProfile(profile) {
  if (!profile?.cached) return null;

  const previewColumns = [
    profile.sku_column_name,
    profile.quantity_column_name,
    profile.barcode_column_name,
  ].filter(Boolean);

  return {
    suggested_sku_column: profile.sku_column_name,
    suggested_quantity_column: profile.quantity_column_name,
    suggested_barcode_column: profile.barcode_column_name,
    preview_columns: previewColumns,
    sample_rows: [],
    from_cache: true,
  };
}

export function previewColumnHeaders(preview) {
  if (!preview) return [];

  const fromApi = preview.preview_columns ?? [];
  if (fromApi.length > 0) {
    return fromApi;
  }

  return [
    preview.suggested_sku_column,
    preview.suggested_quantity_column,
    preview.suggested_barcode_column,
  ].filter(Boolean);
}

function buildPreviewRows(columnHeaders, sampleRows) {
  if (!columnHeaders?.length || !sampleRows?.length) return [];

  const cleanHeaders = columnHeaders.map(cleanColumnName);

  return sampleRows.slice(0, 5).map((row) =>
    columnHeaders.map((header) => row[header] ?? "—")
  );
}

export default function GoogleSheetsPreviewPanel({ preview, loading, error, tabSelected = true }) {
  if (!tabSelected) return null;

  if (loading) {
    return (
      <Card>
        <BlockStack gap="200" inlineAlign="center">
          <Spinner accessibilityLabel="Loading sheet preview" size="small" />
          <Text as="p" variant="bodySm" tone="subdued">
            Detecting columns with AI…
          </Text>
        </BlockStack>
      </Card>
    );
  }

  if (error) {
    return (
      <Card>
        <Text as="p" variant="bodyMd" tone="critical">
          {error}
        </Text>
      </Card>
    );
  }

  if (!preview) return null;

  const columnHeaders = previewColumnHeaders(preview);
  const cleanHeaders = columnHeaders.map(cleanColumnName);
  const tableRows = buildPreviewRows(columnHeaders, preview.sample_rows);

  return (
    <Card>
      <BlockStack gap="400">
        <BlockStack gap="200">
          <Text as="h2" variant="headingMd">
            Sheet preview
          </Text>
          <Text as="p" variant="bodySm" tone="subdued">
            {preview.from_cache
              ? "Using saved column profile. Change the sheet tab to re-detect columns."
              : "Showing detected SKU, quantity, and related columns only."}
          </Text>
          <InlineStack gap="200">
            <Badge tone="success">SKU: {preview.suggested_sku_column}</Badge>
            <Badge tone="success">Qty: {preview.suggested_quantity_column}</Badge>
            {preview.suggested_barcode_column ? (
              <Badge>Barcode: {preview.suggested_barcode_column}</Badge>
            ) : null}
            {preview.from_cache ? <Badge tone="success">cached</Badge> : null}
          </InlineStack>
        </BlockStack>

        {cleanHeaders.length > 0 && tableRows.length > 0 ? (
          <DataTable
            columnContentTypes={cleanHeaders.map(() => "text")}
            headings={cleanHeaders}
            rows={tableRows}
          />
        ) : preview.from_cache ? null : (
          <Text as="p" variant="bodySm" tone="subdued">
            No sample rows to display.
          </Text>
        )}
      </BlockStack>
    </Card>
  );
}
