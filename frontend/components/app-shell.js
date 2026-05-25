"use client";

import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import BrandLogo from "./public/BrandLogo";
import { NAV_ITEMS } from "../lib/nav-items";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import { useTrialStatus } from "../lib/trial-status-context";
import styles from "./app-shell.module.css";

function settingsNavBadge(trialStatus) {
  if (!trialStatus) return null;

  if (trialStatus.trial_expired) {
    return (
      <span className={styles.navBadge} aria-label="Trial expired">
        🔴
      </span>
    );
  }

  if (trialStatus.trial_ending_soon) {
    return (
      <span className={styles.navBadge} aria-label="Trial ending soon">
        ⚠️
      </span>
    );
  }

  return null;
}

export default function AppShell({ children }) {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const shopifyParams = pickShopifyParams(searchParams);
  const { trialStatus } = useTrialStatus();

  return (
    <div className={styles.shell}>
      <div className={styles.body}>
        <nav className={styles.sidebar} aria-label="Main navigation">
          <div className={styles.brand}>
            <BrandLogo
              href={shopifyNavHref("/app", shopifyParams)}
              showName
              size="sm"
            />
          </div>
          <ul className={styles.navList}>
            {NAV_ITEMS.map((item) => {
              const href = shopifyNavHref(item.href, shopifyParams);
              const active =
                pathname === item.href || pathname.startsWith(`${item.href}/`);
              const badge =
                item.href === "/settings" ? settingsNavBadge(trialStatus) : null;

              return (
                <li key={item.href} className={styles.navItem}>
                  <Link
                    href={href}
                    className={`${styles.navLink} ${active ? styles.navLinkActive : ""}`}
                    aria-current={active ? "page" : undefined}
                  >
                    <span className={styles.navLinkLabel}>
                      {item.label}
                      {badge}
                    </span>
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>

        <main className={styles.main}>{children}</main>
      </div>
    </div>
  );
}
