class SupplierUpload < ApplicationRecord
  include MerchantScoped

  belongs_to :supplier
  belongs_to :feed, optional: true
  has_many :mapping_dictionaries, dependent: :nullify
  has_one_attached :file

  STATUSES = %w[pending processing needs_review completed failed].freeze

  validates :status, inclusion: { in: STATUSES }

  after_commit :enqueue_schema_discovery, on: :create

  attr_accessor :enqueue_schema_discovery_after_commit

  def attach_and_enqueue!(uploaded_file)
    Ingestion::UploadValidator.validate!(uploaded_file)

    self.enqueue_schema_discovery_after_commit = true

    transaction do
      save!
      file.attach(uploaded_file)
      raise ActiveRecord::RecordInvalid, self unless file.attached?
    end

    self
  end

  def processing?
    status == "processing"
  end

  def broadcast_target
    "supplier_upload_#{id}"
  end

  private

  def enqueue_schema_discovery
    return unless enqueue_schema_discovery_after_commit

    SupplierSchemaDiscoveryJob.perform_later(id)
  end
end
