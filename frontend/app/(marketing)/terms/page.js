import { getPublicSiteConfig } from "../../../lib/public-site";

export const metadata = {
  title: "Terms and Conditions — NormaList",
};

export default function TermsPage() {
  const { appName, contactEmail } = getPublicSiteConfig();

  return (
    <article className="mx-auto max-w-3xl px-4 py-16 sm:px-6 sm:py-20 lg:px-8">
      <h1 className="text-4xl font-bold text-slate-900">Terms and Conditions</h1>
      <p className="mt-4 text-sm text-slate-500">Last updated: May 2026</p>

      <div className="mt-10 space-y-10 text-slate-600">
        <section>
          <h2 className="text-xl font-semibold text-slate-900">1. Acceptance of terms</h2>
          <p className="mt-3 leading-relaxed">
            By installing or using {appName}, you agree to these terms. If you do not agree, do
            not use the service.
          </p>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">2. Description of service</h2>
          <p className="mt-3 leading-relaxed">
            {appName} helps Shopify merchants map supplier product codes to store SKUs and sync
            inventory quantities from supplier files (CSV, Excel, Google Sheets) to Shopify.
          </p>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">3. Subscription and billing</h2>
          <ul className="mt-3 list-disc space-y-2 pl-6">
            <li>$14 per month after a 14-day free trial</li>
            <li>Billed through Shopify</li>
            <li>Cancel anytime from your Shopify admin</li>
          </ul>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">4. Acceptable use</h2>
          <p className="mt-3 leading-relaxed">
            You agree to use {appName} only for lawful business purposes, with accurate supplier
            data, and in compliance with Shopify&apos;s terms and applicable laws.
          </p>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">5. Limitation of liability</h2>
          <p className="mt-3 leading-relaxed">
            {appName} is provided &quot;as is&quot;. We are not liable for indirect, incidental,
            or consequential damages arising from inventory sync errors, downtime, or data loss.
            You are responsible for reviewing sync results before relying on them in your store.
          </p>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">6. Termination</h2>
          <p className="mt-3 leading-relaxed">
            You may terminate by uninstalling the app. We may suspend access for violation of
            these terms. Upon termination, your data will be handled per our Privacy Policy.
          </p>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">7. Changes to terms</h2>
          <p className="mt-3 leading-relaxed">
            We may update these terms. Continued use after changes constitutes acceptance. Material
            changes will be communicated via the app or email where appropriate.
          </p>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">8. Contact</h2>
          <p className="mt-3 leading-relaxed">
            <a
              href={`mailto:${contactEmail}`}
              className="font-medium text-emerald-700 hover:text-emerald-800"
            >
              {contactEmail}
            </a>
          </p>
        </section>
      </div>
    </article>
  );
}
