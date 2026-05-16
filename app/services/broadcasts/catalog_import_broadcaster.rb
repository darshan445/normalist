module Broadcasts
  class CatalogImportBroadcaster
    def self.call(import, **locals)
      new(import).call(**locals)
    end

    def initialize(import)
      @import = import
    end

    def call(**_locals)
      @import.reload
    end
  end
end
