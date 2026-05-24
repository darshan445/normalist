function apiBase() {
  if (typeof window !== "undefined") return "";
  return process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000";
}

async function fetchWithTimeout(url, options = {}, timeoutMs = 15000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } catch (error) {
    if (error.name === "AbortError") {
      throw new Error("API request timed out — is Rails running on port 3000?");
    }
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

function buildApiUrl(path, { shop } = {}) {
  const origin = typeof window !== "undefined" ? window.location.origin : undefined;
  const url = new URL(`${apiBase()}${path}`, origin);

  if (process.env.NODE_ENV === "development" && shop) {
    url.searchParams.set("shop", shop);
  }

  return url;
}

function buildAuthHeaders({ sessionToken } = {}) {
  const headers = { Accept: "application/json" };

  if (sessionToken) {
    headers.Authorization = `Bearer ${sessionToken}`;
  }

  return headers;
}

async function parseApiResponse(response) {
  let data = null;
  try {
    data = await response.json();
  } catch {
    data = null;
  }

  if (!response.ok) {
    return { ok: false, status: response.status, data };
  }

  return { ok: true, status: response.status, data };
}

function canAuthenticate({ shop, sessionToken }) {
  if (sessionToken) return true;
  return Boolean(process.env.NODE_ENV === "development" && shop);
}

export async function apiGet(path, { shop, sessionToken } = {}) {
  if (!canAuthenticate({ shop, sessionToken })) {
    return { ok: false, status: 0, data: null };
  }

  const url = buildApiUrl(path, { shop });
  const headers = buildAuthHeaders({ sessionToken });

  const response = await fetchWithTimeout(url.toString(), { headers, cache: "no-store" });
  return parseApiResponse(response);
}

export async function apiPost(path, { shop, sessionToken, body } = {}) {
  if (!canAuthenticate({ shop, sessionToken })) {
    return { ok: false, status: 0, data: null };
  }

  const url = buildApiUrl(path, { shop });
  const headers = {
    ...buildAuthHeaders({ sessionToken }),
    "Content-Type": "application/json",
  };

  const response = await fetchWithTimeout(url.toString(), {
    method: "POST",
    headers,
    body: JSON.stringify(body),
    cache: "no-store",
  });

  return parseApiResponse(response);
}

export async function verifyShopifySession({ shop, sessionToken }) {
  return apiGet("/api/v1/session", { shop, sessionToken });
}

export async function fetchDashboard({ shop, sessionToken }) {
  return apiGet("/api/v1/dashboard", { shop, sessionToken });
}

export async function fetchTrialStatus({ shop, sessionToken }) {
  return apiGet("/api/v1/merchants/trial_status", { shop, sessionToken });
}

export async function createBillingCharge({ shop, sessionToken } = {}) {
  return apiPost("/api/v1/billing", { shop, sessionToken });
}

export async function fetchCatalog(path = "/api/v1/catalog", { shop, sessionToken } = {}) {
  return apiGet(path, { shop, sessionToken });
}

export async function fetchReviewQueue({
  page = 1,
  perPage = 25,
  supplierId,
  suggestion,
  shop,
  sessionToken,
} = {}) {
  const params = new URLSearchParams();
  params.set("page", String(page));
  params.set("per_page", String(perPage));
  if (supplierId) params.set("supplier_id", supplierId);
  if (suggestion) params.set("suggestion", suggestion);

  return apiGet(`/api/v1/review_queue?${params.toString()}`, { shop, sessionToken });
}

export async function bulkConfirmReviewQueue({
  supplierId,
  suggestion = "suggested",
  shop,
  sessionToken,
} = {}) {
  return apiPost("/api/v1/review_queue/bulk_confirm", {
    shop,
    sessionToken,
    body: {
      supplier_id: supplierId || undefined,
      suggestion,
    },
  });
}

export async function bulkRejectReviewQueue({
  supplierId,
  suggestion = "all",
  shop,
  sessionToken,
} = {}) {
  return apiPost("/api/v1/review_queue/bulk_reject", {
    shop,
    sessionToken,
    body: {
      supplier_id: supplierId || undefined,
      suggestion,
    },
  });
}

export async function confirmReviewMapping(mappingId, { shop, sessionToken } = {}) {
  return apiPost(`/api/v1/review_queue/${mappingId}/confirm`, { shop, sessionToken });
}

export async function rejectReviewMapping(mappingId, { shop, sessionToken } = {}) {
  return apiPost(`/api/v1/review_queue/${mappingId}/reject`, { shop, sessionToken });
}

export async function manualMatchReviewMapping(mappingId, variantId, { shop, sessionToken } = {}) {
  return apiPost(`/api/v1/review_queue/${mappingId}/manual_match`, {
    shop,
    sessionToken,
    body: { variant_id: variantId },
  });
}

export async function fetchSuppliers({ shop, sessionToken }) {
  return apiGet("/api/v1/suppliers", { shop, sessionToken });
}

export async function fetchSupplier(supplierId, { shop, sessionToken }) {
  return apiGet(`/api/v1/suppliers/${supplierId}`, { shop, sessionToken });
}

export async function fetchSupplierMappings(
  supplierId,
  { page = 1, perPage = 50, status = "all", shop, sessionToken } = {}
) {
  const params = new URLSearchParams();
  params.set("page", String(page));
  params.set("per_page", String(perPage));
  if (status) params.set("status", status);

  return apiGet(
    `/api/v1/suppliers/${supplierId}/mappings?${params.toString()}`,
    { shop, sessionToken }
  );
}

export async function createSupplier({ name }, { shop, sessionToken }) {
  return apiPost("/api/v1/suppliers", {
    shop,
    sessionToken,
    body: { supplier: { name } },
  });
}

export async function createFeed(supplierId, feed, { shop, sessionToken }) {
  return apiPost(`/api/v1/suppliers/${supplierId}/feeds`, {
    shop,
    sessionToken,
    body: { feed },
  });
}

export async function createFeedWithFile(supplierId, { feed_type, file }, { shop, sessionToken }) {
  if (!canAuthenticate({ shop, sessionToken })) {
    return { ok: false, status: 0, data: null };
  }

  const url = buildApiUrl(`/api/v1/suppliers/${supplierId}/feeds`, { shop });
  const formData = new FormData();
  formData.append("feed[feed_type]", feed_type);
  formData.append("file", file);

  const headers = buildAuthHeaders({ sessionToken });

  const response = await fetchWithTimeout(url.toString(), {
    method: "POST",
    headers,
    body: formData,
    cache: "no-store",
  });

  return parseApiResponse(response);
}

export async function uploadFeedFile(supplierId, feedId, file, { shop, sessionToken }) {
  if (!canAuthenticate({ shop, sessionToken })) {
    return { ok: false, status: 0, data: null };
  }

  const url = buildApiUrl(
    `/api/v1/suppliers/${supplierId}/feeds/${feedId}/upload`,
    { shop }
  );
  const formData = new FormData();
  formData.append("file", file);

  const headers = buildAuthHeaders({ sessionToken });

  const response = await fetchWithTimeout(url.toString(), {
    method: "POST",
    headers,
    body: formData,
    cache: "no-store",
  });

  return parseApiResponse(response);
}

export async function fetchFeed(supplierId, feedId, { shop, sessionToken }) {
  return apiGet(`/api/v1/suppliers/${supplierId}/feeds/${feedId}`, { shop, sessionToken });
}

export async function fetchUpload(supplierId, uploadId, { shop, sessionToken }) {
  return apiGet(`/api/v1/suppliers/${supplierId}/uploads/${uploadId}`, {
    shop,
    sessionToken,
  });
}

export async function fetchUploadStatus(supplierId, uploadId, { shop, sessionToken }) {
  return apiGet(`/api/v1/suppliers/${supplierId}/uploads/${uploadId}/status`, {
    shop,
    sessionToken,
  });
}

export async function fetchFeedUploads(supplierId, feedId, { shop, sessionToken }) {
  return apiGet(`/api/v1/suppliers/${supplierId}/feeds/${feedId}/uploads`, {
    shop,
    sessionToken,
  });
}

export async function apiPatch(path, { shop, sessionToken, body } = {}) {
  if (!canAuthenticate({ shop, sessionToken })) {
    return { ok: false, status: 0, data: null };
  }

  const url = buildApiUrl(path, { shop });
  const headers = {
    ...buildAuthHeaders({ sessionToken }),
    "Content-Type": "application/json",
  };

  const response = await fetchWithTimeout(url.toString(), {
    method: "PATCH",
    headers,
    body: JSON.stringify(body),
    cache: "no-store",
  });

  return parseApiResponse(response);
}

export async function updateFeed(supplierId, feedId, feed, { shop, sessionToken }) {
  return apiPatch(`/api/v1/suppliers/${supplierId}/feeds/${feedId}`, {
    shop,
    sessionToken,
    body: { feed },
  });
}

export function shopifyLoginUrl({ shop, host }) {
  const base =
    process.env.NEXT_PUBLIC_API_URL ||
    (typeof window !== "undefined" ? window.location.origin : "http://localhost:3000");

  const url = new URL("/login", base);
  if (shop) url.searchParams.set("shop", shop);
  if (host) url.searchParams.set("host", host);

  return url.toString();
}

export const API_URL = apiBase();
