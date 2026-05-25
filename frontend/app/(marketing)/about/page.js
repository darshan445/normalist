import { getPublicSiteConfig } from "../../../lib/public-site";

export const metadata = {
  title: "About — NormaList",
  description: "Learn why NormaList was built and who it is for.",
};

export default function AboutPage() {
  const { appName, contactName, contactEmail } = getPublicSiteConfig();

  return (
    <article className="mx-auto max-w-3xl px-4 py-16 sm:px-6 sm:py-20 lg:px-8">
      <h1 className="text-4xl font-bold text-slate-900">About {appName}</h1>

      <div className="prose prose-slate mt-10 max-w-none space-y-6 text-slate-600">
        <p className="text-lg leading-relaxed">
          {appName} is inventory normalization built for Shopify merchants who work with
          suppliers that use their own product codes — not your store SKUs.
        </p>

        <h2 className="text-2xl font-semibold text-slate-900">Why we built it</h2>
        <p className="leading-relaxed">
          We built {appName} out of frustration with manual inventory management. Every week,
          the same story: a supplier sends a spreadsheet in their format, with their codes, and
          someone on your team spends hours reformatting it before anything can sync to Shopify.
        </p>

        <h2 className="text-2xl font-semibold text-slate-900">Who it&apos;s for</h2>
        <p className="leading-relaxed">
          {appName} is for Shopify merchants with one or more suppliers who send inventory files
          that don&apos;t match your catalog SKUs. If you map supplier codes once and want every
          future file to resolve automatically — with quantities pushed to Shopify — {appName} is
          for you.
        </p>
      </div>

      <section className="mt-16 rounded-xl border border-slate-200 bg-slate-50 p-8">
        <h2 className="text-xl font-semibold text-slate-900">Contact</h2>
        <dl className="mt-4 space-y-2 text-slate-600">
          <div>
            <dt className="text-sm font-medium text-slate-500">Name</dt>
            <dd>{contactName}</dd>
          </div>
          <div>
            <dt className="text-sm font-medium text-slate-500">Email</dt>
            <dd>
              <a
                href={`mailto:${contactEmail}`}
                className="font-medium text-emerald-700 hover:text-emerald-800"
              >
                {contactEmail}
              </a>
            </dd>
          </div>
        </dl>
      </section>
    </article>
  );
}
