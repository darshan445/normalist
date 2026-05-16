module Broadcasts
  class UploadBroadcaster
    def self.call(upload, **locals)
      new(upload).call(**locals)
    end

    def initialize(upload)
      @upload = upload
    end

    # Turbo Streams removed (API-only backend). Next.js will poll or subscribe later.
    def call(**_locals)
      @upload.reload
    end
  end
end
