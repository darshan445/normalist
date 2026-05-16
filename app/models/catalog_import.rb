class CatalogImport < ApplicationRecord
  include MerchantScoped

  has_one_attached :file

  STATUSES = %w[pending processing completed failed].freeze

  validates :status, inclusion: { in: STATUSES }

  after_create_commit :enqueue_processing

  def broadcast_target
    "catalog_import_#{id}"
  end

  private

  def enqueue_processing
    CatalogImportJob.perform_later(id) if file.attached?
  end
end
