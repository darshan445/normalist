import { NextResponse } from "next/server";

const MARKETING_PATHS = new Set([
  "/",
  "/about",
  "/privacy",
  "/terms",
  "/contact",
]);

export function middleware(request) {
  const url = request.nextUrl.clone();

  if (url.pathname === "/dashboard") {
    url.pathname = "/app";
    return NextResponse.redirect(url);
  }

  const shop = url.searchParams.get("shop");
  const host = url.searchParams.get("host");

  if (shop && host && MARKETING_PATHS.has(url.pathname)) {
    url.pathname = "/app";
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/", "/about", "/privacy", "/terms", "/contact", "/dashboard"],
};
