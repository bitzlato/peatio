# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_07_22_125206) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "accounts", id: :serial, force: :cascade do |t|
    t.integer "member_id", null: false
    t.string "currency_id", limit: 10, null: false
    t.decimal "balance", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "locked", precision: 32, scale: 16, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id", "member_id"], name: "index_accounts_on_currency_id_and_member_id", unique: true
    t.index ["member_id"], name: "index_accounts_on_member_id"
  end

  create_table "adjustments", force: :cascade do |t|
    t.string "reason", null: false
    t.text "description", null: false
    t.bigint "creator_id", null: false
    t.bigint "validator_id"
    t.decimal "amount", precision: 32, scale: 16, null: false
    t.integer "asset_account_code", limit: 2, null: false
    t.string "receiving_account_number", limit: 64, null: false
    t.string "currency_id", null: false
    t.integer "category", limit: 2, null: false
    t.integer "state", limit: 2, null: false
    t.datetime "created_at", precision: 3, null: false
    t.datetime "updated_at", precision: 3, null: false
    t.index ["currency_id", "state"], name: "index_adjustments_on_currency_id_and_state"
    t.index ["currency_id"], name: "index_adjustments_on_currency_id"
  end

  create_table "assets", id: :serial, force: :cascade do |t|
    t.integer "code", null: false
    t.string "currency_id", null: false
    t.string "reference_type"
    t.integer "reference_id"
    t.decimal "debit", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "credit", precision: 32, scale: 16, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_assets_on_currency_id"
    t.index ["reference_type", "reference_id"], name: "index_assets_on_reference_type_and_reference_id"
  end

  create_table "beneficiaries", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.string "currency_id", limit: 10, null: false
    t.string "name", limit: 64, null: false
    t.string "description", default: ""
    t.integer "pin", null: false
    t.integer "state", limit: 2, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "sent_at"
    t.string "data_encrypted", limit: 1024
    t.index ["currency_id"], name: "index_beneficiaries_on_currency_id"
    t.index ["member_id"], name: "index_beneficiaries_on_member_id"
  end

  create_table "blockchains", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.string "name"
    t.string "client", null: false
    t.string "server"
    t.bigint "height", null: false
    t.string "explorer_address"
    t.string "explorer_transaction"
    t.integer "min_confirmations", default: 6, null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_blockchains_on_key", unique: true
    t.index ["status"], name: "index_blockchains_on_status"
  end

  create_table "currencies", id: :string, limit: 10, force: :cascade do |t|
    t.string "type", limit: 30, default: "coin", null: false
    t.decimal "withdraw_limit_24h", precision: 32, scale: 16, default: "0.0", null: false
    t.json "options"
    t.boolean "visible", default: true, null: false
    t.bigint "base_factor", default: 1, null: false
    t.integer "precision", limit: 2, default: 8, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "withdraw_fee", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "deposit_fee", precision: 32, scale: 16, default: "0.0", null: false
    t.string "blockchain_key", limit: 32
    t.string "icon_url"
    t.decimal "min_deposit_amount", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "withdraw_limit_72h", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "min_collection_amount", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "min_withdraw_amount", precision: 32, scale: 16, default: "0.0", null: false
    t.string "name"
    t.integer "position", null: false
    t.boolean "deposit_enabled", default: true, null: false
    t.boolean "withdrawal_enabled", default: true, null: false
    t.text "description"
    t.string "homepage"
    t.decimal "price", precision: 32, scale: 16, default: "1.0", null: false
    t.string "parent_id"
    t.index ["parent_id"], name: "index_currencies_on_parent_id"
    t.index ["position"], name: "index_currencies_on_position"
    t.index ["visible"], name: "index_currencies_on_visible"
  end

  create_table "currencies_wallets", id: false, force: :cascade do |t|
    t.string "currency_id"
    t.integer "wallet_id"
    t.boolean "enable_deposit", default: true, null: false
    t.boolean "enable_withdraw", default: true, null: false
    t.boolean "use_in_balance", default: true, null: false
    t.index ["currency_id", "wallet_id"], name: "index_currencies_wallets_on_currency_id_and_wallet_id", unique: true
    t.index ["currency_id"], name: "index_currencies_wallets_on_currency_id"
    t.index ["wallet_id"], name: "index_currencies_wallets_on_wallet_id"
  end

  create_table "deposits", id: :serial, force: :cascade do |t|
    t.integer "member_id", null: false
    t.string "currency_id", limit: 10, null: false
    t.decimal "amount", precision: 32, scale: 16, null: false
    t.decimal "fee", precision: 32, scale: 16, null: false
    t.citext "txid"
    t.string "aasm_state", limit: 30, null: false
    t.datetime "created_at", precision: 3, null: false
    t.datetime "updated_at", precision: 3, null: false
    t.datetime "completed_at", precision: 3
    t.string "type", limit: 30, null: false
    t.integer "txout"
    t.citext "tid", null: false
    t.string "address", limit: 95
    t.integer "block_number"
    t.string "spread", limit: 1000
    t.text "from_addresses"
    t.integer "transfer_type"
    t.json "data"
    t.string "intention_id"
    t.index ["aasm_state", "member_id", "currency_id"], name: "index_deposits_on_aasm_state_and_member_id_and_currency_id"
    t.index ["currency_id", "intention_id"], name: "index_deposits_on_currency_id_and_intention_id", unique: true, where: "(intention_id IS NOT NULL)"
    t.index ["currency_id", "txid", "txout"], name: "index_deposits_on_currency_id_and_txid_and_txout", unique: true
    t.index ["currency_id"], name: "index_deposits_on_currency_id"
    t.index ["member_id", "txid"], name: "index_deposits_on_member_id_and_txid"
    t.index ["tid"], name: "index_deposits_on_tid"
    t.index ["type"], name: "index_deposits_on_type"
  end

  create_table "engines", force: :cascade do |t|
    t.string "name", null: false
    t.string "driver", null: false
    t.string "uid"
    t.string "url"
    t.string "key_encrypted"
    t.string "secret_encrypted"
    t.string "data_encrypted", limit: 1024
    t.integer "state", default: 1, null: false
  end

  create_table "expenses", id: :serial, force: :cascade do |t|
    t.integer "code", null: false
    t.string "currency_id", null: false
    t.string "reference_type"
    t.integer "reference_id"
    t.decimal "debit", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "credit", precision: 32, scale: 16, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_expenses_on_currency_id"
    t.index ["reference_type", "reference_id"], name: "index_expenses_on_reference_type_and_reference_id"
  end

  create_table "internal_transfers", force: :cascade do |t|
    t.string "currency_id", null: false
    t.decimal "amount", precision: 32, scale: 16, null: false
    t.bigint "sender_id", null: false
    t.bigint "receiver_id", null: false
    t.integer "state", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "jobs", force: :cascade do |t|
    t.string "name", null: false
    t.integer "pointer"
    t.integer "counter"
    t.json "data"
    t.integer "error_code", limit: 2, default: 255, null: false
    t.string "error_message"
    t.datetime "started_at"
    t.datetime "finished_at"
  end

  create_table "liabilities", id: :serial, force: :cascade do |t|
    t.integer "code", null: false
    t.string "currency_id", null: false
    t.integer "member_id"
    t.string "reference_type"
    t.integer "reference_id"
    t.decimal "debit", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "credit", precision: 32, scale: 16, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_liabilities_on_currency_id"
    t.index ["member_id"], name: "index_liabilities_on_member_id"
    t.index ["reference_type", "reference_id"], name: "index_liabilities_on_reference_type_and_reference_id"
  end

  create_table "markets", force: :cascade do |t|
    t.string "symbol", limit: 20, null: false
    t.string "type", default: "spot", null: false
    t.string "base_unit", limit: 10, null: false
    t.string "quote_unit", limit: 10, null: false
    t.bigint "engine_id", null: false
    t.integer "amount_precision", limit: 2, default: 4, null: false
    t.integer "price_precision", limit: 2, default: 4, null: false
    t.decimal "min_price", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "max_price", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "min_amount", precision: 32, scale: 16, default: "0.0", null: false
    t.integer "position", null: false
    t.json "data"
    t.string "state", limit: 32, default: "enabled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_unit", "quote_unit", "type"], name: "index_markets_on_base_unit_and_quote_unit_and_type", unique: true
    t.index ["base_unit"], name: "index_markets_on_base_unit"
    t.index ["engine_id"], name: "index_markets_on_engine_id"
    t.index ["position"], name: "index_markets_on_position"
    t.index ["quote_unit"], name: "index_markets_on_quote_unit"
    t.index ["symbol", "type"], name: "index_markets_on_symbol_and_type", unique: true
  end

  create_table "members", id: :serial, force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uid", limit: 32, null: false
    t.integer "level", null: false
    t.string "role", limit: 16, null: false
    t.string "state", limit: 16, null: false
    t.string "group", limit: 32, default: "vip-0", null: false
    t.string "username"
    t.index ["email"], name: "index_members_on_email", unique: true
    t.index ["uid"], name: "index_members_on_uid", unique: true
    t.index ["username"], name: "index_members_on_username", unique: true, where: "(username IS NOT NULL)"
  end

  create_table "operations_accounts", id: :serial, force: :cascade do |t|
    t.integer "code", null: false
    t.string "type", limit: 10, null: false
    t.string "kind", limit: 30, null: false
    t.string "currency_type", limit: 10, null: false
    t.string "description", limit: 100
    t.string "scope", limit: 10, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_operations_accounts_on_code", unique: true
    t.index ["currency_type"], name: "index_operations_accounts_on_currency_type"
    t.index ["scope"], name: "index_operations_accounts_on_scope"
    t.index ["type", "kind", "currency_type"], name: "index_operations_accounts_on_type_and_kind_and_currency_type", unique: true
    t.index ["type"], name: "index_operations_accounts_on_type"
  end

  create_table "orders", id: :serial, force: :cascade do |t|
    t.string "bid", limit: 10, null: false
    t.string "ask", limit: 10, null: false
    t.string "market_id", limit: 20, null: false
    t.decimal "price", precision: 32, scale: 16
    t.decimal "volume", precision: 32, scale: 16, null: false
    t.decimal "origin_volume", precision: 32, scale: 16, null: false
    t.integer "state", null: false
    t.string "type", limit: 8, null: false
    t.integer "member_id", null: false
    t.datetime "created_at", precision: 0, null: false
    t.datetime "updated_at", precision: 0, null: false
    t.string "ord_type", limit: 30, null: false
    t.decimal "locked", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "origin_locked", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "funds_received", precision: 32, scale: 16, default: "0.0"
    t.integer "trades_count", default: 0, null: false
    t.decimal "maker_fee", precision: 17, scale: 16, default: "0.0", null: false
    t.decimal "taker_fee", precision: 17, scale: 16, default: "0.0", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.string "remote_id"
    t.string "market_type", default: "spot", null: false
    t.index ["member_id"], name: "index_orders_on_member_id"
    t.index ["state"], name: "index_orders_on_state"
    t.index ["type", "market_id", "market_type"], name: "index_orders_on_type_and_market_id_and_market_type"
    t.index ["type", "member_id"], name: "index_orders_on_type_and_member_id"
    t.index ["type", "state", "market_id", "market_type"], name: "index_orders_on_type_and_state_and_market_id_and_market_type"
    t.index ["type", "state", "member_id"], name: "index_orders_on_type_and_state_and_member_id"
    t.index ["updated_at"], name: "index_orders_on_updated_at"
    t.index ["uuid"], name: "index_orders_on_uuid", unique: true
  end

  create_table "payment_addresses", id: :serial, force: :cascade do |t|
    t.string "address", limit: 95
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "secret_encrypted", limit: 255
    t.string "details_encrypted", limit: 1024
    t.bigint "member_id"
    t.bigint "wallet_id"
    t.boolean "remote", default: false, null: false
    t.index ["member_id"], name: "index_payment_addresses_on_member_id"
    t.index ["wallet_id"], name: "index_payment_addresses_on_wallet_id"
  end

  create_table "refunds", force: :cascade do |t|
    t.bigint "deposit_id", null: false
    t.string "state", limit: 30, null: false
    t.string "address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deposit_id"], name: "index_refunds_on_deposit_id"
    t.index ["state"], name: "index_refunds_on_state"
  end

  create_table "revenues", id: :serial, force: :cascade do |t|
    t.integer "code", null: false
    t.string "currency_id", null: false
    t.string "reference_type"
    t.integer "reference_id"
    t.decimal "debit", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "credit", precision: 32, scale: 16, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "member_id"
    t.index ["currency_id"], name: "index_revenues_on_currency_id"
    t.index ["reference_type", "reference_id"], name: "index_revenues_on_reference_type_and_reference_id"
  end

  create_table "stats_member_pnl", force: :cascade do |t|
    t.integer "member_id", null: false
    t.string "pnl_currency_id", limit: 10, null: false
    t.string "currency_id", limit: 10, null: false
    t.decimal "total_credit", precision: 48, scale: 16, default: "0.0"
    t.decimal "total_credit_fees", precision: 48, scale: 16, default: "0.0"
    t.decimal "total_debit_fees", precision: 48, scale: 16, default: "0.0"
    t.decimal "total_debit", precision: 48, scale: 16, default: "0.0"
    t.decimal "total_credit_value", precision: 48, scale: 16, default: "0.0"
    t.decimal "total_debit_value", precision: 48, scale: 16, default: "0.0"
    t.decimal "total_balance_value", precision: 48, scale: 16, default: "0.0"
    t.decimal "average_balance_price", precision: 48, scale: 16, default: "0.0"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["pnl_currency_id", "currency_id", "member_id"], name: "index_currency_ids_and_member_id", unique: true
  end

  create_table "stats_member_pnl_idx", force: :cascade do |t|
    t.string "pnl_currency_id", limit: 10, null: false
    t.string "currency_id", limit: 10, null: false
    t.string "reference_type", limit: 255, null: false
    t.bigint "last_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["pnl_currency_id", "currency_id", "last_id"], name: "index_currency_ids_and_last_id"
    t.index ["pnl_currency_id", "currency_id", "reference_type"], name: "index_currency_ids_and_type", unique: true
  end

  create_table "trades", id: :serial, force: :cascade do |t|
    t.decimal "price", precision: 32, scale: 16, null: false
    t.decimal "amount", precision: 32, scale: 16, null: false
    t.integer "maker_order_id", null: false
    t.integer "taker_order_id", null: false
    t.string "market_id", limit: 20, null: false
    t.datetime "created_at", precision: 3, null: false
    t.datetime "updated_at", precision: 3, null: false
    t.integer "maker_id", null: false
    t.integer "taker_id", null: false
    t.decimal "total", precision: 32, scale: 16, default: "0.0", null: false
    t.string "taker_type", limit: 20, default: "", null: false
    t.string "market_type", default: "spot", null: false
    t.index ["created_at"], name: "index_trades_on_created_at"
    t.index ["maker_id", "market_type", "created_at"], name: "index_trades_on_maker_id_and_market_type_and_created_at"
    t.index ["maker_id", "market_type"], name: "index_trades_on_maker_id_and_market_type"
    t.index ["maker_id"], name: "index_trades_on_maker_id"
    t.index ["maker_order_id"], name: "index_trades_on_maker_order_id"
    t.index ["taker_id", "market_type"], name: "index_trades_on_taker_id_and_market_type"
    t.index ["taker_order_id"], name: "index_trades_on_taker_order_id"
    t.index ["taker_type"], name: "index_trades_on_taker_type"
  end

  create_table "trading_fees", force: :cascade do |t|
    t.string "market_id", limit: 20, default: "any", null: false
    t.string "group", limit: 32, default: "any", null: false
    t.decimal "maker", precision: 7, scale: 6, default: "0.0", null: false
    t.decimal "taker", precision: 7, scale: 6, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "market_type", default: "spot", null: false
    t.index ["group"], name: "index_trading_fees_on_group"
    t.index ["market_id", "market_type", "group"], name: "index_trading_fees_on_market_id_and_market_type_and_group", unique: true
    t.index ["market_id", "market_type"], name: "index_trading_fees_on_market_id_and_market_type"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "currency_id", null: false
    t.string "reference_type"
    t.bigint "reference_id"
    t.string "txid"
    t.string "from_address"
    t.string "to_address"
    t.decimal "amount", precision: 32, scale: 16, default: "0.0", null: false
    t.integer "block_number"
    t.integer "txout"
    t.string "status"
    t.json "options"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id", "txid"], name: "index_transactions_on_currency_id_and_txid", unique: true
    t.index ["currency_id"], name: "index_transactions_on_currency_id"
    t.index ["reference_type", "reference_id"], name: "index_transactions_on_reference_type_and_reference_id"
    t.index ["txid"], name: "index_transactions_on_txid"
  end

  create_table "transfers", id: :serial, force: :cascade do |t|
    t.string "key", limit: 30, null: false
    t.string "description", limit: 255, default: ""
    t.datetime "created_at", precision: 3, null: false
    t.datetime "updated_at", precision: 3, null: false
    t.integer "category", limit: 2, null: false
    t.index ["key"], name: "index_transfers_on_key", unique: true
  end

  create_table "triggers", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.integer "order_type", limit: 2, null: false
    t.binary "value", null: false
    t.integer "state", limit: 2, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_triggers_on_order_id"
    t.index ["order_type"], name: "index_triggers_on_order_type"
    t.index ["state"], name: "index_triggers_on_state"
  end

  create_table "wallets", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64
    t.string "address", null: false
    t.string "status", limit: 32
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "gateway", limit: 20, default: "", null: false
    t.decimal "max_balance", precision: 32, scale: 16, default: "0.0", null: false
    t.string "blockchain_key", limit: 32
    t.integer "kind", null: false
    t.string "settings_encrypted", limit: 1024
    t.jsonb "balance"
    t.boolean "enable_invoice", default: false, null: false
    t.index ["kind"], name: "index_wallets_on_kind"
    t.index ["status"], name: "index_wallets_on_status"
  end

  create_table "whitelisted_smart_contracts", force: :cascade do |t|
    t.string "description"
    t.string "address", null: false
    t.string "state", limit: 30, null: false
    t.string "blockchain_key", limit: 32, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address", "blockchain_key"], name: "index_whitelisted_smart_contracts_on_address_and_blockchain_key", unique: true
  end

  create_table "withdraw_limits", force: :cascade do |t|
    t.string "group", limit: 32, default: "any", null: false
    t.string "kyc_level", limit: 32, default: "any", null: false
    t.decimal "limit_24_hour", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "limit_1_month", precision: 32, scale: 16, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group", "kyc_level"], name: "index_withdraw_limits_on_group_and_kyc_level", unique: true
    t.index ["group"], name: "index_withdraw_limits_on_group"
    t.index ["kyc_level"], name: "index_withdraw_limits_on_kyc_level"
  end

  create_table "withdraws", id: :serial, force: :cascade do |t|
    t.integer "member_id", null: false
    t.string "currency_id", limit: 10, null: false
    t.decimal "amount", precision: 32, scale: 16, null: false
    t.decimal "fee", precision: 32, scale: 16, null: false
    t.datetime "created_at", precision: 3, null: false
    t.datetime "updated_at", precision: 3, null: false
    t.datetime "completed_at", precision: 3
    t.citext "txid"
    t.string "aasm_state", limit: 30, null: false
    t.decimal "sum", precision: 32, scale: 16, null: false
    t.string "type", limit: 30, null: false
    t.citext "tid", null: false
    t.string "rid", limit: 256, null: false
    t.integer "block_number"
    t.string "note", limit: 256
    t.json "error"
    t.bigint "beneficiary_id"
    t.integer "transfer_type"
    t.json "metadata"
    t.index ["aasm_state"], name: "index_withdraws_on_aasm_state"
    t.index ["currency_id", "txid"], name: "index_withdraws_on_currency_id_and_txid", unique: true
    t.index ["currency_id"], name: "index_withdraws_on_currency_id"
    t.index ["member_id"], name: "index_withdraws_on_member_id"
    t.index ["tid"], name: "index_withdraws_on_tid"
    t.index ["type"], name: "index_withdraws_on_type"
  end

end
