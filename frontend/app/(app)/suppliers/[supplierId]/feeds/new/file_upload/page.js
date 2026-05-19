import SetupFileUploadFeed from "../../../../../../../components/setup-file-upload-feed";

export default async function NewFileUploadFeedPage({ params }) {
  const { supplierId } = await params;
  return <SetupFileUploadFeed supplierId={supplierId} />;
}
