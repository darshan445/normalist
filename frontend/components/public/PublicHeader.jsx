import Link from "next/link";
import BrandLogo from "./BrandLogo";
import { getPublicSiteConfig } from "../../lib/public-site";

const NAV_LINKS = [
  { label: "How it works", href: "/#how-it-works" },
  { label: "Pricing", href: "/#pricing" },
  { label: "About", href: "/about" },
  { label: "Contact", href: "/contact" },
];

export default function PublicHeader() {
  const { installUrl } = getPublicSiteConfig();

  return (
    <header className="sticky top-0 z-50 border-b border-slate-200/80 bg-white/95 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-4 sm:px-6 lg:px-8">
        <BrandLogo href="/" showName priority />

        <nav className="hidden items-center gap-8 md:flex" aria-label="Main">
          {NAV_LINKS.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="text-base font-medium text-slate-600 transition hover:text-emerald-700"
            >
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="flex items-center gap-3">
          {installUrl ? (
            <a
              href={installUrl}
              className="inline-flex items-center justify-center rounded-lg bg-emerald-600 px-4 py-2.5 text-base font-semibold text-white shadow-sm transition hover:bg-emerald-700"
            >
              Add to Shopify
            </a>
          ) : null}
        </div>
      </div>

      <nav
        className="flex gap-4 overflow-x-auto border-t border-slate-100 px-4 py-2 md:hidden"
        aria-label="Mobile"
      >
        {NAV_LINKS.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className="whitespace-nowrap text-sm font-medium text-slate-600"
          >
            {item.label}
          </Link>
        ))}
      </nav>
    </header>
  );
}
