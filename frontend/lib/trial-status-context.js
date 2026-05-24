"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import { fetchTrialStatus } from "./api";
import { fetchSessionToken } from "./shopify-session-token";
import { pickShopifyParams } from "./shopify-search-params";

const TrialStatusContext = createContext(null);

export function TrialStatusProvider({ children }) {
  const searchParams = useSearchParams();
  const { shop, embedded } = pickShopifyParams(searchParams);
  const [trialStatus, setTrialStatus] = useState(null);
  const [loadState, setLoadState] = useState({ status: "idle", error: null });

  const reload = useCallback(async () => {
    setLoadState({ status: "loading", error: null });

    try {
      const sessionToken = embedded ? await fetchSessionToken() : null;
      const result = await fetchTrialStatus({ shop, sessionToken });

      if (!result.ok) {
        setLoadState({
          status: "error",
          error: result.data?.message || "Could not load subscription status.",
        });
        setTrialStatus(null);
        return;
      }

      setTrialStatus(result.data);
      setLoadState({ status: "ready", error: null });
    } catch (error) {
      setLoadState({ status: "error", error: error.message });
      setTrialStatus(null);
    }
  }, [shop, embedded]);

  useEffect(() => {
    reload();
  }, [reload]);

  const value = useMemo(
    () => ({
      trialStatus,
      loadState,
      reload,
    }),
    [trialStatus, loadState, reload]
  );

  return (
    <TrialStatusContext.Provider value={value}>{children}</TrialStatusContext.Provider>
  );
}

export function useTrialStatus() {
  const context = useContext(TrialStatusContext);

  if (!context) {
    throw new Error("useTrialStatus must be used within TrialStatusProvider");
  }

  return context;
}
