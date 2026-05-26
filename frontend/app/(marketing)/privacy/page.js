import { getPublicSiteConfig } from "../../../lib/public-site";

export const metadata = {
  title: "Privacy Policy — NormaList",
};

export default function PrivacyPage() {
  const { appName, contactEmail } = getPublicSiteConfig();

  return (
    <article className="mx-auto max-w-3xl px-4 py-16 sm:px-6 sm:py-20 lg:px-8">
      <h1 className="text-4xl font-bold text-slate-900">Privacy Policy</h1>
      <p className="mt-4 text-sm text-slate-500">Last updated: May 2026</p>

      <div className="mt-10 space-y-10 text-slate-600">
        <section>
          <h2 className="text-xl font-semibold text-slate-900">1. Introduction</h2>
          <p className="mt-3 leading-relaxed">
            {appName} (&quot;we&quot;, &quot;our&quot;) respects your privacy. This policy
            explains what data we collect when you use our Shopify app and how we use it to sync
            supplier inventory to your store.
          </p>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">2. Data we collect</h2>
          <ul className="mt-3 list-disc space-y-2 pl-6">
            <li>Shopify store domain</li>
            <li>
              Shopify access token and refresh token (stored in our database with restricted
              access; not shown in the merchant-facing app UI)
            </li>
            <li>Product and variant data from your store</li>
            <li>Supplier inventory files you upload</li>
            <li>Supplier code to SKU mappings you create</li>
          </ul>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">3. How we use your data</h2>
          <ul className="mt-3 list-disc space-y-2 pl-6">
            <li>To sync inventory to your Shopify store</li>
            <li>To remember your supplier code mappings</li>
            <li>To improve AI detection accuracy</li>
          </ul>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">4. Data we do NOT collect</h2>
          <ul className="mt-3 list-disc space-y-2 pl-6">
            <li>Customer personal information (names, emails, addresses, etc.)</li>
            <li>Order data</li>
            <li>Payment information</li>
            <li>Any data beyond what&apos;s needed for inventory sync</li>
          </ul>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">
            5. GDPR and Shopify mandatory webhooks
          </h2>
          <p className="mt-3 leading-relaxed">
            Shopify may send mandatory compliance webhooks when a customer requests their data or
            when data must be redacted. {appName} is built for supplier inventory sync only and does
            not store Shopify customer personal data in our database. When we receive these
            webhooks, we log the request for audit purposes and take no export or redaction action
            because there is no customer data to provide or delete. Shop data is removed when you
            uninstall the app, via the shop/redact webhook (see retention below).
          </p>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">6. Data retention</h2>
          <p className="mt-3 leading-relaxed">
            Your data is retained while your subscription is active. Data is deleted within 30 days
            of uninstalling the app from your Shopify store.
          </p>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">7. Third party services</h2>
          <ul className="mt-3 list-disc space-y-2 pl-6">
            <li>Shopify (store integration)</li>
            <li>Google (Sheets integration)</li>
            <li>
              Gemini AI (column detection only; only a small snippet of each file is sent, not the
              full upload)
            </li>
          </ul>
        </section>

        <section>
          <h2 className="text-xl font-semibold text-slate-900">8. Contact</h2>
          <p className="mt-3 leading-relaxed">
            Questions about this policy:{" "}
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
