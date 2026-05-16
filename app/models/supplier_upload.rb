class SupplierUpload < ApplicationRecord
  include MerchantScoped

  belongs_to :supplier
  has_one_attached :file

  STATUSES = %w[pending processing completed failed awaiting_mapping].freeze

  validates :status, inclusion: { in: STATUSES }
  validate :file_must_be_attached, on: :create

  after_create_commit :enqueue_processing

  def file_must_be_attached
    errors.add(:file, "can't be blank") unless file.attached?
  end

  def processing?
    status == "processing"
  end

  def broadcast_target
    "supplier_upload_#{id}"
  end

  private

  def enqueue_processing
    ProcessSupplierFileJob.perform_later(id) if file.attached?
  end
end
