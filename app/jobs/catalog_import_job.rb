class CatalogImportJob < ApplicationJob
  queue_as :catalog

  REQUIRED_HEADERS = %w[master_sku product_title variant_title barcode].freeze

  def perform(catalog_import_id)
    import = CatalogImport.find(catalog_import_id)
    merchant = import.merchant

    import.reload

    unless import.file.attached?
      import.update!(status: "failed", error_message: "No file attached to import")
      Broadcasts::CatalogImportBroadcaster.call(import)
      return
    end

    import.update!(status: "processing")
    Broadcasts::CatalogImportBroadcaster.call(import)

    path = write_tempfile(import)
    imported = 0
    errors = []

    CSV.foreach(path, headers: true, encoding: "bom|utf-8").with_index(2) do |row, line|
      attrs = row.to_h.transform_keys { |k| k.to_s.strip.downcase }
      missing = REQUIRED_HEADERS - attrs.keys
      if missing.any?
        errors << { line: line, message: "Missing columns: #{missing.join(', ')}" }
        next
      end

      variant = merchant.variants.find_or_initialize_by(master_sku: attrs["master_sku"].strip)
      variant.assign_attributes(
        product_title: attrs["product_title"].strip,
        variant_title: attrs["variant_title"].strip,
        barcode: attrs["barcode"].presence&.strip,
        status: "active"
      )
      if variant.save
        imported += 1
      else
        errors << { line: line, message: variant.errors.full_messages.join(", ") }
      end
    end

    import.update!(
      status: "completed",
      imported_count: imported,
      error_count: errors.size,
      row_errors: errors
    )
    Broadcasts::CatalogImportBroadcaster.call(import)
  rescue StandardError => e
    import&.update!(status: "failed", error_message: e.message)
    Broadcasts::CatalogImportBroadcaster.call(import) if import
    raise
  ensure
    @tempfile&.close!
  end

  private

  def write_tempfile(import)
    @tempfile = Tempfile.new([ "catalog", ".csv" ])
    @tempfile.binmode
    import.file.open do |file|
      @tempfile.write(file.read)
    end
    @tempfile.rewind
    @tempfile.path
  end
end
