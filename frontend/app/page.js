import HomePage from "../components/home-page";
import { pickShopifyParams } from "../lib/shopify-search-params";

export default async function Page({ searchParams }) {
  const params = await searchParams;
  const sp = new URLSearchParams(params);
  const { shop, host, embedded } = pickShopifyParams(sp);

  return <HomePage shop={shop} host={host} embedded={embedded} />;
}
