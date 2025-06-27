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

ActiveRecord::Schema[7.2].define(version: 2025_06_20_155039) do
  create_schema "auth"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "pgbouncer"
  create_schema "realtime"
  create_schema "storage"
  create_schema "vault"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_graphql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "supabase_vault"
  enable_extension "uuid-ossp"

  create_table "complaint_comments", force: :cascade do |t|
    t.bigint "complaint_id", null: false
    t.string "user_email", null: false
    t.string "user_type", null: false
    t.text "comment", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["complaint_id"], name: "index_complaint_comments_on_complaint_id"
    t.index ["user_type"], name: "index_complaint_comments_on_user_type"
  end

  create_table "complaints", force: :cascade do |t|
    t.string "complaint_type", null: false
    t.string "user_id", null: false
    t.text "complain"
    t.string "attachment"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["complaint_type"], name: "index_complaints_on_complaint_type"
    t.index ["status"], name: "index_complaints_on_status"
    t.index ["user_id"], name: "index_complaints_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "user_type", default: "regular", null: false
    t.string "token_jti"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["token_jti"], name: "index_users_on_token_jti"
    t.index ["user_type"], name: "index_users_on_user_type"
  end

  add_foreign_key "complaint_comments", "complaints"
end
