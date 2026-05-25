import CtaButton from "../../components/public/CtaButton";
import { getPublicSiteConfig } from "../../lib/public-site";

export const metadata = {
  title: "NormaList — Supplier inventory sync for Shopify",
  description:
    "Stop manually reformatting supplier files. AI-powered column detection, permanent SKU mapping, and direct Shopify sync.",
};

const PAIN_POINTS = [
  "Your supplier sends files with their own product codes that don't match your Shopify SKUs",
  "You spend hours every week manually reformatting spreadsheets",
  "Every supplier has a different file format",
  "Existing sync apps assume your supplier uses the same SKUs as your store",
];

const STEPS = [
  {
    title: "Upload any supplier file",
    body: "CSV, Excel or Google Sheets URL. Any format, any column names.",
  },
  {
    title: "AI detects the structure",
    body: "Automatically identifies which column is the product code and which is quantity. Suggests SKU matches from your catalog.",
  },
  {
    title: "Confirm mappings once",
    body: "Match supplier codes to your Shopify SKUs. NormaList remembers forever.",
  },
  {
    title: "Automatic sync forever",
    body: "Every future upload resolves instantly. Quantities sync directly to Shopify. No manual work ever again.",
  },
];

const FEATURES = [
  {
    title: "AI column detection",
    body: "Automatically identifies SKU and quantity columns in any file format.",
  },
  {
    title: "AI SKU matching",
    body: "Suggests which supplier codes match your Shopify variants.",
  },
  {
    title: "Permanent mapping memory",
    body: "Map once, automatic forever. Never asked again.",
  },
  {
    title: "CSV and Excel support",
    body: "Upload any supplier file format.",
  },
  {
    title: "Google Sheets sync",
    body: "Paste a public sheet URL. Syncs automatically on your schedule — every 6 hours, 12 hours, daily or weekly.",
  },
  {
    title: "Direct Shopify sync",
    body: "Quantities update directly in your store. No manual import needed.",
  },
  {
    title: "Multiple suppliers",
    body: "Manage all your suppliers in one place. Each with their own mapping profile.",
  },
];

export default function HomePage() {
  const { appName } = getPublicSiteConfig();

  return (
    <>
      <section className="relative overflow-hidden bg-gradient-to-b from-emerald-50 to-white">
        <div className="mx-auto max-w-6xl px-4 py-20 sm:px-6 sm:py-28 lg:px-8">
          <div className="mx-auto max-w-3xl text-center">
            <h1 className="text-4xl font-bold tracking-tight text-slate-900 sm:text-5xl lg:text-6xl">
              Stop manually reformatting supplier inventory files
            </h1>
            <p className="mt-6 text-lg leading-relaxed text-slate-600 sm:text-xl">
              AI-powered inventory sync for Shopify. Map supplier codes to your SKUs once.
              Sync automatically forever.
            </p>
            <div className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
              <CtaButton />
              <p className="text-sm text-slate-500">No credit card required.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="border-y border-slate-200 bg-slate-50 py-16 sm:py-20">
        <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
          <h2 className="text-center text-3xl font-bold text-slate-900">Sound familiar?</h2>
          <ul className="mx-auto mt-10 grid max-w-3xl gap-4 sm:grid-cols-2">
            {PAIN_POINTS.map((point) => (
              <li
                key={point}
                className="flex gap-3 rounded-xl border border-slate-200 bg-white p-5 text-slate-700 shadow-sm"
              >
                <span className="text-emerald-600" aria-hidden>
                  ✕
                </span>
                <span>{point}</span>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section id="how-it-works" className="py-16 sm:py-24 scroll-mt-20">
        <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
          <h2 className="text-center text-3xl font-bold text-slate-900">
            How {appName} works
          </h2>
          <ol className="mt-14 grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
            {STEPS.map((step, index) => (
              <li key={step.title} className="relative">
                <span className="flex h-10 w-10 items-center justify-center rounded-full bg-emerald-600 text-sm font-bold text-white">
                  {index + 1}
                </span>
                <h3 className="mt-4 text-lg font-semibold text-slate-900">{step.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-slate-600">{step.body}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="border-t border-slate-200 bg-slate-50 py-16 sm:py-24">
        <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
          <h2 className="text-center text-3xl font-bold text-slate-900">Everything you need</h2>
          <ul className="mt-14 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {FEATURES.map((feature) => (
              <li
                key={feature.title}
                className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm"
              >
                <h3 className="font-semibold text-slate-900">{feature.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-slate-600">{feature.body}</p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section id="pricing" className="py-16 sm:py-24 scroll-mt-20">
        <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
          <h2 className="text-center text-3xl font-bold text-slate-900">Simple pricing</h2>
          <div className="mx-auto mt-12 max-w-md rounded-2xl border-2 border-emerald-600 bg-white p-8 text-center shadow-lg">
            <p className="text-5xl font-bold text-slate-900">
              $14
              <span className="text-lg font-medium text-slate-500"> / month</span>
            </p>
            <p className="mt-2 font-medium text-emerald-700">Everything included</p>
            <ul className="mt-8 space-y-2 text-left text-sm text-slate-600">
              <li>Unlimited suppliers</li>
              <li>Unlimited variants</li>
              <li>Unlimited uploads</li>
              <li>14 day free trial</li>
              <li>No credit card required</li>
              <li>Cancel anytime</li>
            </ul>
            <div className="mt-8">
              <CtaButton className="w-full" />
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
