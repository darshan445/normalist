import Providers from "./providers";
import ShopifyScripts from "../components/shopify-scripts";
import "./globals.css";

export const metadata = {
  title: "NormaList",
  description: "Supplier inventory normalization for Shopify merchants",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <head>
        {/* App Bridge: meta + script must be first in <head> (no next/script async). */}
        <ShopifyScripts />
      </head>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
