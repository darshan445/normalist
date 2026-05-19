# frozen_string_literal: true

class FixActiveStorageAttachmentsRecordIdForUuid < ActiveRecord::Migration[8.1]
  def up
    remove_index :active_storage_attachments,
                 name: :index_active_storage_attachments_uniqueness,
                 if_exists: true

    # bigint record_id cannot store UUID primary keys (attachments were saved as 0).
    execute "DELETE FROM active_storage_attachments"

    remove_column :active_storage_attachments, :record_id
    add_column :active_storage_attachments, :record_id, :uuid, null: false

    add_index :active_storage_attachments,
              %i[record_type record_id name blob_id],
              name: :index_active_storage_attachments_uniqueness,
              unique: true
  end

  def down
    remove_index :active_storage_attachments,
                 name: :index_active_storage_attachments_uniqueness,
                 if_exists: true

    execute "DELETE FROM active_storage_attachments"

    remove_column :active_storage_attachments, :record_id
    add_column :active_storage_attachments, :record_id, :bigint, null: false

    add_index :active_storage_attachments,
              %i[record_type record_id name blob_id],
              name: :index_active_storage_attachments_uniqueness,
              unique: true
  end
end
