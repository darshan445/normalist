import { NextResponse } from "next/server";

export function middleware(request) {
  if (request.nextUrl.pathname === "/dashboard") {
    const url = request.nextUrl.clone();
    url.pathname = "/";
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: "/dashboard",
};
