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

ActiveRecord::Schema[7.0].define(version: 2025_08_01_184431) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "article_likes", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "article_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.index ["article_id", "user_id"], name: "index_article_likes_on_article_id_and_user_id", unique: true
  end

  create_table "articles", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "access", limit: 20
    t.boolean "active"
    t.string "author", limit: 100
    t.string "category", limit: 20
    t.text "text"
    t.string "title", limit: 100
    t.boolean "markdown", default: true
    t.integer "user_id"
    t.integer "year", limit: 2
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "nlikes"
    t.integer "categories", default: 0, null: false
    t.index ["access"], name: "index_articles_on_access"
    t.index ["active"], name: "index_articles_on_active"
    t.index ["author"], name: "index_articles_on_author"
    t.index ["category"], name: "index_articles_on_category"
    t.index ["title"], name: "index_articles_on_title"
    t.index ["user_id"], name: "index_articles_on_user_id"
    t.index ["year"], name: "index_articles_on_year"
  end

  create_table "bad_logins", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", limit: 32
    t.string "ip", limit: 50
    t.datetime "created_at", precision: nil
    t.index ["created_at"], name: "index_bad_logins_on_created_at"
    t.index ["email"], name: "index_bad_logins_on_email"
    t.index ["ip"], name: "index_bad_logins_on_ip"
  end

  create_table "carts", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "status", limit: 20, default: "unpaid"
    t.decimal "total", precision: 9, scale: 2
    t.decimal "original_total", precision: 9, scale: 2
    t.string "payment_method", limit: 20
    t.string "payment_ref", limit: 50
    t.string "confirmation_email", limit: 50
    t.string "confirmation_error"
    t.text "confirmation_text"
    t.boolean "confirmation_sent", default: false
    t.string "payment_name", limit: 100
    t.integer "user_id"
    t.datetime "payment_completed", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "payment_account", limit: 32
    t.string "latest_charge", limit: 50
    t.index ["confirmation_email"], name: "index_carts_on_confirmation_email"
    t.index ["payment_method"], name: "index_carts_on_payment_method"
    t.index ["payment_name"], name: "index_carts_on_payment_name"
    t.index ["status"], name: "index_carts_on_status"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "champions", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "category", limit: 20
    t.string "notes", limit: 140
    t.string "winners"
    t.integer "year", limit: 2
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "image_id"
    t.index ["category"], name: "index_champions_on_category"
    t.index ["image_id"], name: "fk_rails_4b4d78bb46"
    t.index ["winners"], name: "index_champions_on_winners"
    t.index ["year"], name: "index_champions_on_year"
  end

  create_table "clubs", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 50
    t.string "district", limit: 50
    t.string "city", limit: 50
    t.string "contact", limit: 50
    t.string "email", limit: 50
    t.string "phone", limit: 50
    t.string "web", limit: 100
    t.string "address", limit: 100
    t.string "meet"
    t.string "county", limit: 20
    t.decimal "lat", precision: 10, scale: 7
    t.decimal "long", precision: 10, scale: 7
    t.boolean "active"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "junior_only", default: false
    t.boolean "has_junior_section", default: false
    t.index ["active"], name: "index_clubs_on_active"
    t.index ["city"], name: "index_clubs_on_city"
    t.index ["county"], name: "index_clubs_on_county"
    t.index ["name"], name: "index_clubs_on_name"
  end

  create_table "documents", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.text "content"
    t.string "content_type"
    t.integer "changed_by_id"
    t.string "authorized_by"
    t.text "reason_changed"
    t.boolean "is_current"
    t.integer "previous_version_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.index ["changed_by_id"], name: "fk_rails_a07bebd5fe"
    t.index ["previous_version_id"], name: "fk_rails_0fa5b3f041"
  end

  create_table "downloads", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "access", limit: 20
    t.string "data_file_name"
    t.string "data_content_type"
    t.integer "data_file_size"
    t.datetime "data_updated_at", precision: nil
    t.string "description", limit: 150
    t.string "www1_path", limit: 128
    t.integer "user_id"
    t.integer "year", limit: 2
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["access"], name: "index_downloads_on_access"
    t.index ["data_content_type"], name: "index_downloads_on_data_content_type"
    t.index ["description"], name: "index_downloads_on_description"
    t.index ["user_id"], name: "index_downloads_on_user_id"
    t.index ["www1_path"], name: "index_downloads_on_www1_path"
    t.index ["year"], name: "index_downloads_on_year"
  end

  create_table "episodes", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "article_id"
    t.integer "series_id"
    t.integer "number", limit: 2
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["article_id"], name: "index_episodes_on_article_id"
    t.index ["number"], name: "index_episodes_on_number"
    t.index ["series_id"], name: "index_episodes_on_series_id"
  end

  create_table "events", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.boolean "active"
    t.string "category", limit: 25
    t.string "contact", limit: 50
    t.string "email", limit: 50
    t.string "flyer_file_name"
    t.string "flyer_content_type"
    t.integer "flyer_file_size"
    t.datetime "flyer_updated_at", precision: nil
    t.decimal "lat", precision: 10, scale: 7
    t.string "location", limit: 100
    t.decimal "long", precision: 10, scale: 7
    t.string "name", limit: 75
    t.string "note", limit: 512
    t.string "phone", limit: 25
    t.decimal "prize_fund", precision: 8, scale: 2
    t.string "source", limit: 8, default: "www2"
    t.date "start_date"
    t.date "end_date"
    t.string "url"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "sections"
    t.string "pairings_url"
    t.string "results_url"
    t.string "live_games_url"
    t.string "report_url"
    t.string "streaming_url"
    t.string "live_games_url2"
    t.index ["active"], name: "index_events_on_active"
    t.index ["category"], name: "index_events_on_category"
    t.index ["end_date"], name: "index_events_on_end_date"
    t.index ["location"], name: "index_events_on_location"
    t.index ["name"], name: "index_events_on_name"
    t.index ["start_date"], name: "index_events_on_start_date"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "failures", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "details"
    t.datetime "created_at", precision: nil
    t.boolean "active", default: true
  end

  create_table "fees", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "type", limit: 40
    t.string "name", limit: 100
    t.decimal "amount", precision: 9, scale: 2
    t.decimal "discounted_amount", precision: 9, scale: 2
    t.string "years", limit: 7
    t.integer "year", limit: 2
    t.integer "days", limit: 2
    t.date "start_date"
    t.date "end_date"
    t.date "sale_start"
    t.date "sale_end"
    t.date "age_ref_date"
    t.date "discount_deadline"
    t.integer "min_age", limit: 1
    t.integer "max_age", limit: 1
    t.integer "min_rating", limit: 2
    t.integer "max_rating", limit: 2
    t.string "url"
    t.boolean "active", default: false
    t.boolean "player_required", default: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "event_id"
    t.string "sections"
    t.boolean "organizer_only"
    t.index ["active"], name: "index_fees_on_active"
    t.index ["end_date"], name: "index_fees_on_end_date"
    t.index ["event_id"], name: "index_fees_on_event_id"
    t.index ["name"], name: "index_fees_on_name"
    t.index ["sale_end"], name: "index_fees_on_sale_end"
    t.index ["sale_start"], name: "index_fees_on_sale_start"
    t.index ["start_date"], name: "index_fees_on_start_date"
    t.index ["type"], name: "index_fees_on_type"
  end

  create_table "fide_player_files", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.text "description"
    t.integer "players_in_file", limit: 2, default: 0
    t.integer "new_fide_records", limit: 1, default: 0
    t.integer "new_icu_mappings", limit: 1, default: 0
    t.integer "user_id"
    t.datetime "created_at", precision: nil
  end

  create_table "fide_players", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "last_name"
    t.string "first_name"
    t.string "fed", limit: 3
    t.string "title", limit: 3
    t.string "gender", limit: 1
    t.integer "born", limit: 2
    t.integer "rating", limit: 2
    t.integer "icu_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["icu_id"], name: "index_fide_players_on_icu_id"
    t.index ["last_name", "first_name"], name: "index_fide_players_on_last_name_and_first_name"
  end

  create_table "fide_ratings", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "fide_id"
    t.integer "rating", limit: 2
    t.integer "games", limit: 2
    t.date "list"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["fide_id"], name: "index_fide_ratings_on_fide_id"
    t.index ["list"], name: "index_fide_ratings_on_list"
  end

  create_table "games", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "annotator", limit: 50
    t.string "black", limit: 50
    t.integer "black_elo", limit: 2
    t.string "date", limit: 10
    t.string "eco", limit: 3
    t.string "event", limit: 50
    t.string "fen", limit: 100
    t.text "moves"
    t.integer "pgn_id"
    t.integer "ply", limit: 2
    t.string "result", limit: 3
    t.string "round", limit: 7
    t.string "signature", limit: 32
    t.string "site", limit: 50
    t.string "white", limit: 50
    t.integer "white_elo", limit: 2
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "in_link"
    t.index ["black"], name: "index_games_on_black"
    t.index ["date"], name: "index_games_on_date"
    t.index ["eco"], name: "index_games_on_eco"
    t.index ["event"], name: "index_games_on_event"
    t.index ["result"], name: "index_games_on_result"
    t.index ["signature"], name: "index_games_on_signature"
    t.index ["white"], name: "index_games_on_white"
  end

  create_table "icu_players", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "club"
    t.string "address"
    t.string "phone_numbers"
    t.string "fed", limit: 3
    t.string "title", limit: 3
    t.string "gender", limit: 1
    t.text "note"
    t.date "dob"
    t.date "joined"
    t.boolean "deceased"
    t.integer "master_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["last_name", "first_name"], name: "index_icu_players_on_last_name_and_first_name"
  end

  create_table "icu_ratings", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.date "list"
    t.integer "icu_id"
    t.integer "rating", limit: 2
    t.boolean "full", default: false
    t.integer "original_rating", limit: 2
    t.boolean "original_full"
    t.index ["icu_id"], name: "index_icu_ratings_on_icu_id"
    t.index ["list", "icu_id"], name: "index_icu_ratings_on_list_and_icu_id", unique: true
    t.index ["list"], name: "index_icu_ratings_on_list"
  end

  create_table "images", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "data_file_name"
    t.string "data_content_type"
    t.integer "data_file_size"
    t.datetime "data_updated_at", precision: nil
    t.string "caption"
    t.string "dimensions"
    t.string "credit", limit: 100
    t.string "source", limit: 8, default: "www2"
    t.integer "year", limit: 2
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["caption"], name: "index_images_on_caption"
    t.index ["credit"], name: "index_images_on_credit"
    t.index ["user_id"], name: "index_images_on_user_id"
    t.index ["year"], name: "index_images_on_year"
  end

  create_table "items", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "type", limit: 40
    t.integer "player_id"
    t.integer "fee_id"
    t.integer "cart_id"
    t.string "description"
    t.string "player_data"
    t.date "start_date"
    t.date "end_date"
    t.decimal "cost", precision: 9, scale: 2
    t.string "status", limit: 20, default: "unpaid"
    t.string "source", limit: 8, default: "www2"
    t.string "payment_method", limit: 20
    t.string "notes", limit: 1000, default: "--- []\n"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "section"
    t.index ["cart_id"], name: "index_items_on_cart_id"
    t.index ["end_date"], name: "index_items_on_end_date"
    t.index ["fee_id"], name: "index_items_on_fee_id"
    t.index ["payment_method"], name: "index_items_on_payment_method"
    t.index ["player_id"], name: "index_items_on_player_id"
    t.index ["source"], name: "index_items_on_source"
    t.index ["start_date"], name: "index_items_on_start_date"
    t.index ["status"], name: "index_items_on_status"
    t.index ["type"], name: "index_items_on_type"
  end

  create_table "journal_entries", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "journalable_id"
    t.string "journalable_type", limit: 50
    t.string "action", limit: 50
    t.string "column", limit: 50
    t.string "by"
    t.string "ip", limit: 50
    t.string "from"
    t.string "to"
    t.datetime "created_at", precision: nil
    t.string "source", limit: 8, default: "www2"
    t.index ["action"], name: "index_journal_entries_on_action"
    t.index ["by"], name: "index_journal_entries_on_by"
    t.index ["column"], name: "index_journal_entries_on_column"
    t.index ["ip"], name: "index_journal_entries_on_ip"
    t.index ["journalable_id", "journalable_type"], name: "index_journal_entries_on_journalable_id_and_journalable_type"
    t.index ["journalable_id"], name: "index_journal_entries_on_journalable_id"
    t.index ["journalable_type"], name: "index_journal_entries_on_journalable_type"
  end

  create_table "live_ratings", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "icu_id"
    t.integer "rating", limit: 2
    t.integer "games", limit: 2
    t.boolean "full", default: false
    t.integer "last_rating", limit: 2
    t.boolean "last_full", default: false
    t.index ["icu_id"], name: "index_live_ratings_on_icu_id", unique: true
  end

  create_table "logins", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "error"
    t.string "roles"
    t.string "ip", limit: 50
    t.datetime "created_at", precision: nil
    t.index ["created_at", "user_id"], name: "index_logins_on_created_at_and_user_id"
    t.index ["created_at"], name: "index_logins_on_created_at"
    t.index ["error"], name: "index_logins_on_error"
    t.index ["ip"], name: "index_logins_on_ip"
    t.index ["user_id"], name: "index_logins_on_user_id"
  end

  create_table "mail_events", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "accepted", default: 0
    t.integer "rejected", default: 0
    t.integer "delivered", default: 0
    t.integer "failed", default: 0
    t.integer "opened", default: 0
    t.integer "clicked", default: 0
    t.integer "unsubscribed", default: 0
    t.integer "complained", default: 0
    t.integer "stored", default: 0
    t.integer "total", default: 0
    t.integer "other", default: 0
    t.date "date"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "pages", limit: 1
    t.index ["date"], name: "index_mail_events_on_date"
  end

  create_table "news", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.boolean "active"
    t.date "date"
    t.string "headline", limit: 100
    t.text "summary"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "nlikes"
    t.string "category", limit: 20
    t.integer "categories", default: 0, null: false
    t.index ["active"], name: "index_news_on_active"
    t.index ["date"], name: "index_news_on_date"
    t.index ["headline"], name: "index_news_on_headline"
    t.index ["user_id"], name: "index_news_on_user_id"
  end

  create_table "news_likes", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "news_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.index ["news_id", "user_id"], name: "index_news_likes_on_news_id_and_user_id", unique: true
  end

  create_table "officers", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "role", limit: 20
    t.integer "player_id"
    t.integer "rank", limit: 1
    t.boolean "executive", default: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "active", default: true
  end

  create_table "old_rating_histories", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "old_tournament_id"
    t.integer "icu_player_id"
    t.integer "old_rating", limit: 2
    t.integer "new_rating", limit: 2
    t.integer "performance_rating", limit: 2
    t.integer "tournament_rating", limit: 2
    t.integer "bonus", limit: 2
    t.integer "games", limit: 1
    t.integer "kfactor", limit: 1
    t.decimal "actual_score", precision: 3, scale: 1
    t.decimal "expected_score", precision: 8, scale: 6
    t.index ["icu_player_id"], name: "index_old_rating_histories_on_icu_player_id"
    t.index ["old_tournament_id", "icu_player_id"], name: "by_icu_player_old_tournament", unique: true
    t.index ["old_tournament_id"], name: "index_old_rating_histories_on_old_tournament_id"
  end

  create_table "old_ratings", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "icu_id"
    t.integer "rating", limit: 2
    t.integer "games", limit: 2
    t.boolean "full", default: false
    t.index ["icu_id"], name: "index_old_ratings_on_icu_id", unique: true
  end

  create_table "old_tournaments", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.date "date"
    t.integer "player_count", limit: 2
  end

  create_table "payment_errors", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "cart_id"
    t.string "message"
    t.string "details"
    t.string "payment_name", limit: 100
    t.string "confirmation_email", limit: 50
    t.datetime "created_at", precision: nil
    t.index ["cart_id"], name: "index_payment_errors_on_cart_id"
    t.index ["confirmation_email"], name: "index_payment_errors_on_confirmation_email"
  end

  create_table "pgns", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "comment"
    t.string "content_type"
    t.integer "duplicates", default: 0
    t.string "file_name"
    t.integer "file_size", default: 0
    t.integer "game_count", default: 0
    t.integer "imports", default: 0
    t.integer "lines", default: 0
    t.string "problem"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["comment"], name: "index_pgns_on_comment"
    t.index ["file_name"], name: "index_pgns_on_file_name"
    t.index ["user_id"], name: "index_pgns_on_user_id"
  end

  create_table "players", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "first_name", limit: 50
    t.string "last_name", limit: 50
    t.string "status", limit: 25
    t.string "source", limit: 25
    t.integer "player_id"
    t.string "gender", limit: 1
    t.date "dob"
    t.date "joined"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "club_id"
    t.string "fed", limit: 3
    t.string "player_title", limit: 3
    t.string "arbiter_title", limit: 3
    t.string "trainer_title", limit: 3
    t.string "email", limit: 50
    t.string "address"
    t.string "home_phone", limit: 30
    t.string "mobile_phone", limit: 30
    t.string "work_phone", limit: 30
    t.text "note"
    t.integer "legacy_rating", limit: 2
    t.string "legacy_rating_type", limit: 20
    t.integer "legacy_games", limit: 2
    t.integer "latest_rating", limit: 2
    t.string "privacy"
    t.index ["club_id"], name: "index_players_on_club_id"
    t.index ["dob"], name: "index_players_on_dob"
    t.index ["fed"], name: "index_players_on_fed"
    t.index ["first_name", "last_name"], name: "index_players_on_first_name_and_last_name"
    t.index ["first_name"], name: "index_players_on_first_name"
    t.index ["gender"], name: "index_players_on_gender"
    t.index ["joined"], name: "index_players_on_joined"
    t.index ["last_name"], name: "index_players_on_last_name"
    t.index ["player_id"], name: "index_players_on_player_id"
    t.index ["source"], name: "index_players_on_source"
    t.index ["status"], name: "index_players_on_status"
  end

  create_table "publications", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "rating_list_id"
    t.integer "last_tournament_id"
    t.text "report"
    t.datetime "created_at", precision: nil
    t.integer "total", limit: 3
    t.integer "creates", limit: 3
    t.integer "remains", limit: 3
    t.integer "updates", limit: 3
    t.integer "deletes", limit: 3
    t.text "notes"
    t.index ["rating_list_id"], name: "index_publications_on_rating_list_id"
  end

  create_table "rating_lists", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.date "date"
    t.date "tournament_cut_off"
    t.datetime "created_at", precision: nil
    t.date "payment_cut_off"
    t.index ["date"], name: "index_rating_lists_on_date"
  end

  create_table "rating_runs", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id"
    t.string "status"
    t.text "report"
    t.integer "start_tournament_id"
    t.integer "last_tournament_id"
    t.integer "start_tournament_rorder"
    t.integer "last_tournament_rorder"
    t.string "start_tournament_name"
    t.string "last_tournament_name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "reason", limit: 100, default: "", null: false
  end

  create_table "refunds", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "cart_id"
    t.integer "user_id"
    t.string "error"
    t.decimal "amount", precision: 9, scale: 2
    t.datetime "created_at", precision: nil
    t.boolean "automatic", default: true
    t.index ["cart_id"], name: "index_refunds_on_cart_id"
    t.index ["created_at"], name: "index_refunds_on_created_at"
    t.index ["user_id"], name: "index_refunds_on_user_id"
  end

  create_table "relays", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "from", limit: 50
    t.string "to"
    t.string "provider_id", limit: 50
    t.integer "officer_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "enabled", default: true
  end

  create_table "results", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "competition"
    t.string "player1"
    t.string "player2"
    t.string "score"
    t.integer "reporter_id"
    t.boolean "active"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "message"
  end

  create_table "series", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "title", limit: 100
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["title"], name: "index_series_on_title"
  end

  create_table "sponsors", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.integer "weight"
    t.string "weblink"
    t.string "contact_email"
    t.string "contact_name"
    t.string "contact_phone"
    t.integer "clicks"
    t.date "valid_until"
    t.text "notes"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "logo_file_name"
    t.string "logo_content_type"
    t.integer "logo_file_size"
    t.datetime "logo_updated_at", precision: nil
    t.integer "eyeballs"
  end

  create_table "subscriptions", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "icu_id"
    t.string "season", limit: 7
    t.string "category", limit: 8
    t.date "pay_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["category"], name: "index_subscriptions_on_category"
    t.index ["icu_id"], name: "index_subscriptions_on_icu_id"
    t.index ["season"], name: "index_subscriptions_on_season"
  end

  create_table "tournaments", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.boolean "active"
    t.string "category", limit: 20
    t.string "city", limit: 50
    t.text "details"
    t.string "format", limit: 20
    t.string "name", limit: 80
    t.integer "year", limit: 2
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["active"], name: "index_tournaments_on_active"
    t.index ["category"], name: "index_tournaments_on_category"
    t.index ["city"], name: "index_tournaments_on_city"
    t.index ["format"], name: "index_tournaments_on_format"
    t.index ["name"], name: "index_tournaments_on_name"
    t.index ["year"], name: "index_tournaments_on_year"
  end

  create_table "translations", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "locale", limit: 2
    t.string "key"
    t.string "value"
    t.string "english"
    t.string "old_english"
    t.string "user"
    t.boolean "active"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["active"], name: "index_translations_on_active"
    t.index ["english"], name: "index_translations_on_english"
    t.index ["key"], name: "index_translations_on_key"
    t.index ["user"], name: "index_translations_on_user"
    t.index ["value"], name: "index_translations_on_value"
  end

  create_table "uploads", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "format"
    t.string "content_type"
    t.string "file_type"
    t.integer "size"
    t.integer "tournament_id"
    t.integer "user_id"
    t.text "error"
    t.datetime "created_at", precision: nil
    t.index ["tournament_id"], name: "index_uploads_on_tournament_id"
    t.index ["user_id"], name: "index_uploads_on_user_id"
  end

  create_table "user_inputs", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "fee_id"
    t.string "type", limit: 40
    t.string "label", limit: 100
    t.boolean "required", default: true
    t.integer "max_length", limit: 2
    t.decimal "min_amount", precision: 6, scale: 2, default: "1.0"
    t.string "date_constraint", limit: 30, default: "none"
    t.index ["fee_id"], name: "index_user_inputs_on_fee_id"
    t.index ["type"], name: "index_user_inputs_on_type"
  end

  create_table "users", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "email"
    t.string "roles"
    t.string "encrypted_password", limit: 32
    t.string "salt", limit: 32
    t.string "status", default: "OK"
    t.integer "player_id"
    t.date "expires_on"
    t.datetime "verified_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "theme", limit: 16
    t.string "locale", limit: 2, default: "en"
    t.boolean "hide_header", default: false
    t.datetime "last_used_at", precision: nil
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.boolean "disallow_reporting"
    t.boolean "junior_newsletter"
    t.boolean "newsletter"
    t.index ["email"], name: "index_users_on_email"
    t.index ["expires_on"], name: "index_users_on_expires_on"
    t.index ["last_used_at"], name: "index_users_on_last_used_at"
    t.index ["player_id"], name: "index_users_on_player_id"
    t.index ["roles"], name: "index_users_on_roles"
    t.index ["status"], name: "index_users_on_status"
    t.index ["verified_at"], name: "index_users_on_verified_at"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "champions", "images"
  add_foreign_key "documents", "documents", column: "previous_version_id"
  add_foreign_key "documents", "users", column: "changed_by_id"
  add_foreign_key "fees", "events"
end
