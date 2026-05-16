"use client";

import RequireShopifyAuth from "./require-shopify-auth";
import Dashboard from "./dashboard";

export default function HomePage({ shop, host, embedded }) {
  return (
    <RequireShopifyAuth shop={shop} host={host} embedded={embedded}>
      {({ session }) => <Dashboard session={session} />}
    </RequireShopifyAuth>
  );
}
