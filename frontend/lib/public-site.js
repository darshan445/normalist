/**
 * Public marketing site configuration (NEXT_PUBLIC_* env vars).
 */

export function getPublicSiteConfig() {
  const appName = process.env.NEXT_PUBLIC_APP_NAME || "NormaList";
  const installUrl = process.env.NEXT_PUBLIC_INSTALL_URL || "";
  const contactEmail =
    process.env.NEXT_PUBLIC_CONTACT_EMAIL || "hello@normalist.space";
  const contactName = process.env.NEXT_PUBLIC_CONTACT_NAME || "NormaList Team";
  const supportEmail =
    process.env.NEXT_PUBLIC_SUPPORT_EMAIL || contactEmail;

  return {
    appName,
    installUrl,
    contactEmail,
    contactName,
    supportEmail,
    year: new Date().getFullYear(),
  };
}
