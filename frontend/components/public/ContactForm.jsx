"use client";

import { useState } from "react";
import { getPublicSiteConfig } from "../../lib/public-site";

export default function ContactForm() {
  const { supportEmail, contactName } = getPublicSiteConfig();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [submitted, setSubmitted] = useState(false);

  function handleSubmit(event) {
    event.preventDefault();

    const subject = encodeURIComponent(`NormaList contact from ${name || "visitor"}`);
    const body = encodeURIComponent(
      `Name: ${name}\nEmail: ${email}\n\n${message}`
    );
    window.location.href = `mailto:${supportEmail}?subject=${subject}&body=${body}`;
    setSubmitted(true);
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      <div>
        <label htmlFor="contact-name" className="block text-sm font-medium text-slate-700">
          Name
        </label>
        <input
          id="contact-name"
          name="name"
          type="text"
          required
          value={name}
          onChange={(e) => setName(e.target.value)}
          className="mt-1 w-full rounded-lg border border-slate-300 px-4 py-2.5 text-slate-900 shadow-sm focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20"
        />
      </div>

      <div>
        <label htmlFor="contact-email" className="block text-sm font-medium text-slate-700">
          Email
        </label>
        <input
          id="contact-email"
          name="email"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="mt-1 w-full rounded-lg border border-slate-300 px-4 py-2.5 text-slate-900 shadow-sm focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20"
        />
      </div>

      <div>
        <label htmlFor="contact-message" className="block text-sm font-medium text-slate-700">
          Message
        </label>
        <textarea
          id="contact-message"
          name="message"
          required
          rows={5}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          className="mt-1 w-full rounded-lg border border-slate-300 px-4 py-2.5 text-slate-900 shadow-sm focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20"
        />
      </div>

      <button
        type="submit"
        className="inline-flex w-full items-center justify-center rounded-lg bg-emerald-600 px-6 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-emerald-700 sm:w-auto"
      >
        Send Message
      </button>

      {submitted ? (
        <p className="text-sm text-emerald-700" role="status">
          Your email client should open to send the message to {contactName}.
        </p>
      ) : null}
    </form>
  );
}
