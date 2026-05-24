# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_24_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "feeds", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "feed_type", null: false
    t.datetime "last_synced_at"
    t.uuid "merchant_id", null: false
    t.string "name", null: false
    t.string "schedule"
    t.string "status", default: "active", null: false
    t.uuid "supplier_id", null: false
    t.datetime "updated_at", null: false
    t.index ["feed_type"], name: "index_feeds_on_feed_type"
    t.index ["merchant_id", "status"], name: "index_feeds_on_merchant_id_and_status"
    t.index ["merchant_id", "supplier_id"], name: "index_feeds_on_merchant_id_and_supplier_id"
  end

  create_table "mapping_dictionaries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.float "confidence_score"
    t.datetime "created_at", null: false
    t.datetime "last_seen"
    t.string "master_sku"
    t.uuid "merchant_id", null: false
    t.integer "pending_quantity"
    t.string "platform_inventory_id"
    t.string "platform_variant_id"
    t.string "quantity_behavior", default: "add", null: false
    t.string "status", default: "pending", null: false
    t.string "supplier_code", null: false
    t.uuid "supplier_id", null: false
    t.uuid "supplier_upload_id"
    t.datetime "updated_at", null: false
    t.index ["last_seen"], name: "index_mapping_dictionaries_on_last_seen"
    t.index ["merchant_id", "status"], name: "index_mapping_dictionaries_on_merchant_id_and_status"
    t.index ["merchant_id", "supplier_id", "supplier_code"], name: "index_mapping_dict_on_merchant_supplier_code", unique: true
    t.index ["merchant_id", "supplier_id", "supplier_code"], name: "index_mapping_dictionaries_on_merchant_supplier_review", where: "((status)::text = 'review'::text)"
    t.index ["merchant_id"], name: "index_mapping_dictionaries_on_merchant_id"
    t.index ["quantity_behavior"], name: "index_mapping_dictionaries_on_quantity_behavior"
    t.index ["supplier_id"], name: "index_mapping_dictionaries_on_supplier_id"
    t.index ["supplier_upload_id"], name: "index_mapping_dictionaries_on_supplier_upload_id"
  end

  create_table "merchants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "access_token"
    t.datetime "catalog_synced_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "location_id"
    t.string "name", null: false
    t.string "plan_status", default: "trialing", null: false
    t.string "platform"
    t.string "platform_domain"
    t.string "refresh_token"
    t.datetime "refresh_token_expires_at"
    t.datetime "trial_ends_at"
    t.datetime "trial_starts_at"
    t.datetime "updated_at", null: false
    t.index ["platform_domain"], name: "index_merchants_on_platform_domain", unique: true, where: "(platform_domain IS NOT NULL)"
    t.index ["trial_ends_at"], name: "index_merchants_on_trial_ends_at"
  end

  create_table "plan_changes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "from_plan"
    t.string "initiated_by", default: "merchant", null: false
    t.uuid "merchant_id", null: false
    t.text "note"
    t.string "reason", null: false
    t.uuid "subscription_id"
    t.string "to_plan", null: false
    t.datetime "updated_at", null: false
    t.index ["initiated_by"], name: "index_plan_changes_on_initiated_by"
    t.index ["merchant_id", "created_at"], name: "index_plan_changes_on_merchant_id_and_created_at"
    t.index ["merchant_id"], name: "index_plan_changes_on_merchant_id"
    t.index ["reason"], name: "index_plan_changes_on_reason"
    t.index ["subscription_id"], name: "index_plan_changes_on_subscription_id"
    t.index ["to_plan"], name: "index_plan_changes_on_to_plan"
  end

  create_table "plan_features", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "feature_key", null: false
    t.string "limit_type"
    t.integer "limit_value"
    t.uuid "plan_id", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_plan_features_on_enabled"
    t.index ["feature_key"], name: "index_plan_features_on_feature_key"
    t.index ["plan_id", "feature_key"], name: "index_plan_features_on_plan_id_and_feature_key", unique: true
    t.index ["plan_id"], name: "index_plan_features_on_plan_id"
  end

  create_table "plans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "interval", default: "monthly", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.boolean "public", default: true, null: false
    t.integer "sort_order", default: 0, null: false
    t.integer "trial_days", default: 14, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_plans_on_active"
    t.index ["key"], name: "index_plans_on_key", unique: true
    t.index ["public"], name: "index_plans_on_public"
    t.index ["sort_order"], name: "index_plans_on_sort_order"
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "activated_at"
    t.datetime "billing_on"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "frozen_at"
    t.string "interval", default: "monthly", null: false
    t.uuid "merchant_id", null: false
    t.uuid "plan_id", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "shopify_charge_id", null: false
    t.jsonb "shopify_payload", default: {}, null: false
    t.string "status", default: "pending", null: false
    t.integer "trial_days", default: 14
    t.datetime "trial_ends_at"
    t.datetime "updated_at", null: false
    t.index ["activated_at"], name: "index_subscriptions_on_activated_at"
    t.index ["billing_on"], name: "index_subscriptions_on_billing_on"
    t.index ["merchant_id", "status"], name: "index_subscriptions_on_merchant_id_and_status"
    t.index ["merchant_id"], name: "index_subscriptions_on_merchant_id"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["shopify_charge_id"], name: "index_subscriptions_on_shopify_charge_id", unique: true
    t.index ["status"], name: "index_subscriptions_on_status"
  end

  create_table "supplier_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "barcode_column"
    t.datetime "created_at", null: false
    t.jsonb "file_schema_map", default: {}, null: false
    t.datetime "last_used_at"
    t.uuid "merchant_id", null: false
    t.string "quantity_column", null: false
    t.jsonb "raw_headers", default: [], null: false
    t.uuid "supplier_id", null: false
    t.string "unique_column", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id", "supplier_id"], name: "index_supplier_profiles_on_merchant_id_and_supplier_id", unique: true
    t.index ["merchant_id"], name: "index_supplier_profiles_on_merchant_id"
    t.index ["supplier_id"], name: "index_supplier_profiles_on_supplier_id"
  end

  create_table "supplier_uploads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.uuid "feed_id"
    t.uuid "merchant_id", null: false
    t.jsonb "output", default: []
    t.integer "resolved_count", default: 0, null: false
    t.integer "row_count"
    t.string "stage"
    t.string "status", default: "pending", null: false
    t.uuid "supplier_id", null: false
    t.integer "unique_code_count"
    t.integer "unresolved_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["feed_id"], name: "index_supplier_uploads_on_feed_id"
    t.index ["merchant_id", "status"], name: "index_supplier_uploads_on_merchant_id_and_status"
    t.index ["merchant_id"], name: "index_supplier_uploads_on_merchant_id"
    t.index ["supplier_id"], name: "index_supplier_uploads_on_supplier_id"
  end

  create_table "suppliers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "merchant_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_suppliers_on_merchant_id"
  end

  create_table "variants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "barcode"
    t.datetime "created_at", null: false
    t.datetime "embedded_at"
    t.vector "embedding", limit: 1536
    t.string "master_sku", null: false
    t.uuid "merchant_id", null: false
    t.boolean "needs_sku", default: false, null: false
    t.string "platform"
    t.string "platform_inventory_id"
    t.string "platform_variant_id"
    t.string "product_title", null: false
    t.string "status", default: "active", null: false
    t.datetime "synced_at"
    t.datetime "updated_at", null: false
    t.string "variant_title", null: false
    t.index ["embedding"], name: "index_variants_on_embedding_hnsw", opclass: :vector_cosine_ops, using: :hnsw
    t.index ["merchant_id", "barcode"], name: "index_variants_on_merchant_id_and_barcode"
    t.index ["merchant_id", "master_sku"], name: "index_variants_on_merchant_id_and_master_sku", unique: true
    t.index ["merchant_id", "needs_sku"], name: "index_variants_on_merchant_id_and_needs_sku"
    t.index ["merchant_id", "platform_variant_id"], name: "index_variants_on_merchant_id_and_platform_variant_id"
    t.index ["merchant_id", "status"], name: "index_variants_on_merchant_id_and_status"
    t.index ["merchant_id"], name: "index_variants_on_merchant_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "feeds", "merchants"
  add_foreign_key "feeds", "suppliers"
  add_foreign_key "mapping_dictionaries", "merchants"
  add_foreign_key "mapping_dictionaries", "supplier_uploads"
  add_foreign_key "mapping_dictionaries", "suppliers"
  add_foreign_key "plan_changes", "merchants"
  add_foreign_key "plan_changes", "subscriptions"
  add_foreign_key "plan_features", "plans"
  add_foreign_key "subscriptions", "merchants"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "supplier_profiles", "merchants"
  add_foreign_key "supplier_profiles", "suppliers"
  add_foreign_key "supplier_uploads", "feeds"
  add_foreign_key "supplier_uploads", "merchants"
  add_foreign_key "supplier_uploads", "suppliers"
  add_foreign_key "suppliers", "merchants"
  add_foreign_key "variants", "merchants"
end
