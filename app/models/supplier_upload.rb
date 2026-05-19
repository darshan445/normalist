class SupplierUpload < ApplicationRecord
  include MerchantScoped

  belongs_to :supplier
  belongs_to :feed, optional: true
  has_many :mapping_dictionaries, dependent: :nullify
  has_one_attached :file

  STATUSES = %w[pending processing needs_review completed failed].freeze

  validates :status, inclusion: { in: STATUSES }

  def attach_and_enqueue!(uploaded_file)
    transaction do
      save!
      file.attach(uploaded_file)
      raise ActiveRecord::RecordInvalid, self unless file.attached?

      SupplierSchemaDiscoveryJob.perform_later(id)
    end
    self
  end

  def processing?
    status == "processing"
  end

  def broadcast_target
    "supplier_upload_#{id}"
  end
end
