import SetupFileUploadFeed from "@/components/setup-file-upload-feed";
import SetupGoogleSheetsFeed from "@/components/setup-google-sheets-feed";

export default async function FeedSetupPage({ params, searchParams }) {
  const { supplierId } = await params;
  const query = await searchParams;
  const feedType = query?.type === "google_sheets" ? "google_sheets" : "file_upload";

  if (feedType === "google_sheets") {
    return <SetupGoogleSheetsFeed supplierId={supplierId} />;
  }

  return <SetupFileUploadFeed supplierId={supplierId} />;
}
