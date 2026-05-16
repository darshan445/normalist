module UploadFileParsable
  extend ActiveSupport::Concern

  private

  def parse_upload_file(upload)
    upload.reload

    unless upload.file.attached?
      upload.update!(status: "failed", stage: "Failed", error_message: "No file attached to upload")
      Broadcasts::UploadBroadcaster.call(upload) if upload.persisted?
      return nil
    end

    upload.file.open do |file|
      return Ingestion::FileParser.call(file, filename: upload.file.filename.to_s)
    end
  end
end
