"use client";

import { AppProvider } from "@shopify/polaris";
import "@shopify/polaris/build/esm/styles.css";
import enTranslations from "@shopify/polaris/locales/en.json";
import Link from "next/link";

function PolarisLink({ url, children, external, ...rest }) {
  if (external) {
    return (
      <a href={url} target="_blank" rel="noopener noreferrer" {...rest}>
        {children}
      </a>
    );
  }

  return (
    <Link href={url || "/"} {...rest}>
      {children}
    </Link>
  );
}

export default function Providers({ children }) {
  return (
    <AppProvider i18n={enTranslations} linkComponent={PolarisLink}>
      {children}
    </AppProvider>
  );
}
