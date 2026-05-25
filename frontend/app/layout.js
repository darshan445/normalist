import ShopifyScripts from "../components/shopify-scripts";
import "./globals.css";

export const metadata = {
  title: {
    default: "NormaList",
    template: "%s | NormaList",
  },
  description:
    "AI-powered supplier inventory sync for Shopify. Map supplier codes once, sync automatically forever.",
  icons: {
    icon: "/logo.png",
    apple: "/logo.png",
  },
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <head>
        {/* App Bridge: meta + script must be first in <head> (no next/script async). */}
        <ShopifyScripts />
      </head>
      <body>{children}</body>
    </html>
  );
}
