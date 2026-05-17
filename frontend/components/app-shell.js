"use client";

import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import { NAV_ITEMS } from "../lib/nav-items";
import { pickShopifyParams } from "../lib/shopify-search-params";
import { shopifyNavHref } from "../lib/shopify-nav-href";
import styles from "./app-shell.module.css";

export default function AppShell({ children }) {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const shopifyParams = pickShopifyParams(searchParams);

  const brandHref = shopifyNavHref("/", shopifyParams);

  return (
    <div className={styles.shell}>
      <header className={styles.header}>
        <Link href={brandHref} className={styles.brand}>
          NormaList
        </Link>
      </header>

      <div className={styles.body}>
        <nav className={styles.sidebar} aria-label="Main navigation">
          <ul className={styles.navList}>
            {NAV_ITEMS.map((item) => {
              const href = shopifyNavHref(item.href, shopifyParams);
              const active =
                item.href === "/"
                  ? pathname === "/"
                  : pathname === item.href || pathname.startsWith(`${item.href}/`);

              return (
                <li key={item.href} className={styles.navItem}>
                  <Link
                    href={href}
                    className={`${styles.navLink} ${active ? styles.navLinkActive : ""}`}
                    aria-current={active ? "page" : undefined}
                  >
                    {item.label}
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
