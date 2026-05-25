import { NextResponse } from "next/server";

/**
 * Contact form endpoint (stub). Production can wire nodemailer or a transactional email API.
 * The public contact form currently uses mailto: for reliability without server config.
 */
export async function POST(request) {
  let body;

  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { name, email, message } = body ?? {};
  const supportEmail =
    process.env.NEXT_PUBLIC_SUPPORT_EMAIL ||
    process.env.NEXT_PUBLIC_CONTACT_EMAIL ||
    "hello@normalist.space";

  if (!name?.trim() || !email?.trim() || !message?.trim()) {
    return NextResponse.json(
      { error: "Name, email, and message are required." },
      { status: 422 }
    );
  }

  console.info("[contact]", { name, email, messageLength: message.length });

  return NextResponse.json({
    ok: true,
    message: "Message received. Use mailto fallback on the contact page if email delivery is not configured.",
    mailto: `mailto:${supportEmail}`,
  });
}
