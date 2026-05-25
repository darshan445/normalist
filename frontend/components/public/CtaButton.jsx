import { getPublicSiteConfig } from "../../lib/public-site";

export default function CtaButton({ className = "", children = "Start Free Trial — 14 days" }) {
  const { installUrl } = getPublicSiteConfig();

  if (!installUrl) {
    return (
      <span className={`inline-flex rounded-lg bg-slate-300 px-6 py-3 text-sm font-semibold text-slate-600 ${className}`}>
        {children}
      </span>
    );
  }

  return (
    <a
      href={installUrl}
      className={`inline-flex items-center justify-center rounded-lg bg-emerald-600 px-6 py-3 text-sm font-semibold text-white shadow-md transition hover:bg-emerald-700 ${className}`}
    >
      {children}
    </a>
  );
}
