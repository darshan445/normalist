import FeedShow from "../../../../../../components/feed-show";

export default async function FeedShowPage({ params }) {
  const { supplierId, feedId } = await params;
  return <FeedShow supplierId={supplierId} feedId={feedId} />;
}
