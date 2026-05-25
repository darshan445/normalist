import Image from "next/image";
import Link from "next/link";
import { getPublicSiteConfig } from "../../lib/public-site";

const SIZES = {
  sm: 32,
  md: 36,
  lg: 48,
};

/**
 * NormaList brand mark from /logo.png.
 * @param {object} props
 * @param {string} [props.href] — wrap in Link when set; omit for static display
 * @param {boolean} [props.showName]
 * @param {"sm"|"md"|"lg"} [props.size]
 * @param {string} [props.className]
 */
export default function BrandLogo({
  href,
  showName = true,
  size = "md",
  className = "",
  priority = false,
}) {
  const { appName } = getPublicSiteConfig();
  const dimension = SIZES[size] ?? SIZES.md;

  const content = (
    <span className={`inline-flex items-center gap-2.5 ${className}`.trim()}>
      <Image
        src="/logo.png"
        alt={`${appName} logo`}
        width={dimension}
        height={dimension}
        className="shrink-0 rounded-lg"
        priority={priority}
      />
      {showName ? (
        <span className="font-semibold text-slate-900">{appName}</span>
      ) : null}
    </span>
  );

  if (href) {
    return (
      <Link href={href} className="inline-flex no-underline hover:opacity-90">
        {content}
      </Link>
    );
  }

  return content;
}
