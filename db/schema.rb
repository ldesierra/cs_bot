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

ActiveRecord::Schema[7.2].define(version: 2025_10_17_182543) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "biddeds", force: :cascade do |t|
    t.integer "bidded_by", null: false
    t.string "item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "bidded_by = ANY (ARRAY[0, 1, 2])", name: "check_bidded_by_values"
  end

  create_table "hourly_sent_users", force: :cascade do |t|
    t.bigint "hourly_sent_id", null: false
    t.bigint "user_id", null: false
    t.datetime "viewed_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hourly_sent_id", "user_id"], name: "index_hourly_sent_users_on_hourly_sent_id_and_user_id", unique: true
    t.index ["hourly_sent_id"], name: "index_hourly_sent_users_on_hourly_sent_id"
    t.index ["user_id"], name: "index_hourly_sent_users_on_user_id"
  end

  create_table "hourly_sents", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.integer "buy_price"
    t.index ["item_id"], name: "index_hourly_sents_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.bigint "transaction_involved_id"
    t.string "name"
    t.float "float"
    t.float "fade"
    t.float "blue"
    t.string "stickers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "item_id"
    t.index ["transaction_involved_id"], name: "index_items_on_transaction_involved_id"
  end

  create_table "portfolios", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_portfolios_on_user_id"
  end

  create_table "snipes", force: :cascade do |t|
    t.string "name_to_seek"
    t.decimal "max_price", precision: 10, scale: 2
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "min_float"
    t.float "max_float"
    t.boolean "to_bid", null: false
    t.index ["user_id"], name: "index_snipes_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.float "buy_price"
    t.float "sell"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id"], name: "index_transactions_on_portfolio_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "off_skin_balance", precision: 10, scale: 2, default: "0.0"
    t.decimal "balance", precision: 10, scale: 2, default: "0.0"
    t.string "user_number"
    t.json "seen_item_ids", default: []
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["user_number"], name: "index_users_on_user_number", unique: true
  end

  add_foreign_key "hourly_sent_users", "hourly_sents"
  add_foreign_key "hourly_sent_users", "users"
  add_foreign_key "hourly_sents", "items"
  add_foreign_key "items", "transactions", column: "transaction_involved_id"
  add_foreign_key "portfolios", "users"
  add_foreign_key "snipes", "users"
  add_foreign_key "transactions", "portfolios"
end
