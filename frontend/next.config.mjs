/** @type {import('next').NextConfig} */
const apiBackend = process.env.API_BACKEND_URL || "http://127.0.0.1:3000";
const ngrokHost = process.env.NEXT_ALLOWED_DEV_ORIGIN?.replace(/^https?:\/\//, "");

const nextConfig = {
  transpilePackages: ["@shopify/polaris"],
  ...(ngrokHost ? { allowedDevOrigins: [ngrokHost] } : {}),
  async rewrites() {
    return [
      { source: "/api/:path*", destination: `${apiBackend}/api/:path*` },
      { source: "/login", destination: `${apiBackend}/login` },
      { source: "/login/:path*", destination: `${apiBackend}/login/:path*` },
      { source: "/auth/:path*", destination: `${apiBackend}/auth/:path*` },
      { source: "/webhooks/:path*", destination: `${apiBackend}/webhooks/:path*` },
    ];
  },
  async headers() {
    return [
      {
        source: "/:path*",
        headers: [
          {
            key: "Content-Security-Policy",
            value:
              "frame-ancestors https://*.myshopify.com https://admin.shopify.com https://*.shopify.com https://*.myshopify.io;",
          },
        ],
      },
    ];
  },
};

export default nextConfig;
