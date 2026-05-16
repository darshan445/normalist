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
        <ShopifyScripts />
      </head>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
