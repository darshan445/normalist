"use client";

import { createContext, useContext } from "react";

const SessionContext = createContext(null);

export function SessionProvider({ session, children }) {
  return <SessionContext.Provider value={session}>{children}</SessionContext.Provider>;
}

export function useAppSession() {
  return useContext(SessionContext);
}
