import Link from "next/link";
import { getPublicSiteConfig } from "../../lib/public-site";

const FOOTER_LINKS = [
  { label: "Home", href: "/" },
  { label: "About", href: "/about" },
  { label: "Privacy Policy", href: "/privacy" },
  { label: "Terms", href: "/terms" },
  { label: "Contact", href: "/contact" },
];

export default function PublicFooter() {
  const { appName, contactEmail, year } = getPublicSiteConfig();

  return (
    <footer className="border-t border-slate-200 bg-slate-50">
      <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6 lg:px-8">
        <div className="flex flex-col gap-8 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-lg font-semibold text-slate-900">{appName}</p>
            <p className="mt-2 text-sm text-slate-600">
              AI-powered supplier inventory sync for Shopify.
            </p>
            <a
              href={`mailto:${contactEmail}`}
              className="mt-3 inline-block text-sm font-medium text-emerald-700 hover:text-emerald-800"
            >
              {contactEmail}
            </a>
          </div>

          <ul className="flex flex-wrap gap-x-6 gap-y-2 text-sm">
            {FOOTER_LINKS.map((item) => (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className="text-slate-600 transition hover:text-emerald-700"
                >
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>

        <p className="mt-10 border-t border-slate-200 pt-8 text-center text-sm text-slate-500">
          © {year} {appName}. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
