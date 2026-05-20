function parseVariantTitle(variantTitle) {
  if (!variantTitle) return {};

  const segments = variantTitle
    .split(/\s*\/\s*/)
    .map((part) => part.trim())
    .filter(Boolean);

  if (segments.length < 2) {
    return { variant: variantTitle };
  }

  return {
    color: segments[0],
    size: segments.slice(1).join(" / "),
  };
}

export function formatMetadata(fields) {
  const parts = [];

  if (fields.product) parts.push(`Product: ${fields.product}`);
  if (fields.variant) parts.push(`Variant: ${fields.variant}`);
  if (fields.title) parts.push(`Title: ${fields.title}`);
  if (fields.size) parts.push(`Size: ${fields.size}`);
  if (fields.color) parts.push(`Color: ${fields.color}`);

  return parts.join(" · ");
}

export function merchantProductFromVariant(variant) {
  if (!variant) return null;

  const parsed = parseVariantTitle(variant.variant_title);

  const fields = {
    product: variant.product_title || null,
    variant: variant.variant_title || null,
    title: variant.product_title || null,
    size: parsed.size || null,
    color: parsed.color || null,
  };

  return {
    id: variant.id,
    unique_code: variant.master_sku,
    barcode: variant.barcode || null,
    ...fields,
    metadata: formatMetadata(fields),
  };
}

export function variantSelectLabel(variant) {
  if (!variant) return "—";

  const code = variant.master_sku || variant.unique_code || "—";
  const metadata =
    variant.metadata || merchantProductFromVariant(variant)?.metadata;

  if (metadata) {
    return `${code} — ${metadata}`;
  }

  return code;
}

export function formatConfidence(score) {
  if (score == null || Number.isNaN(score)) return null;
  return `${Math.round(score * 100)}%`;
}

const SUGGESTION_THRESHOLD = 0.5;

export function confidenceInfo(score) {
  if (score == null || Number.isNaN(score) || score < SUGGESTION_THRESHOLD) {
    return { label: "Couldn't identify", tone: "warning" };
  }

  return { label: formatConfidence(score), tone: "info" };
}
