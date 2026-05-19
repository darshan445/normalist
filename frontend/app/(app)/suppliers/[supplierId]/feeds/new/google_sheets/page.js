import SetupGoogleSheetsFeed from "../../../../../../../components/setup-google-sheets-feed";

export default async function NewGoogleSheetsFeedPage({ params }) {
  const { supplierId } = await params;
  return <SetupGoogleSheetsFeed supplierId={supplierId} />;
}
