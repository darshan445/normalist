import ContactForm from "../../../components/public/ContactForm";
import { getPublicSiteConfig } from "../../../lib/public-site";

export const metadata = {
  title: "Contact — NormaList",
};

export default function ContactPage() {
  const { contactName, contactEmail } = getPublicSiteConfig();

  return (
    <div className="mx-auto max-w-6xl px-4 py-16 sm:px-6 sm:py-20 lg:px-8">
      <div className="mx-auto max-w-xl">
        <h1 className="text-4xl font-bold text-slate-900">Get in touch</h1>
        <p className="mt-4 text-slate-600">We typically respond within 24 hours.</p>

        <dl className="mt-8 space-y-3 rounded-xl border border-slate-200 bg-slate-50 p-6 text-slate-700">
          <div>
            <dt className="text-sm font-medium text-slate-500">Name</dt>
            <dd className="font-medium">{contactName}</dd>
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

        <div className="mt-10">
          <ContactForm />
        </div>
      </div>
    </div>
  );
}
