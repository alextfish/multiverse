# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20141026221002) do

  create_table "cards", force: true do |t|
    t.string   "code"
    t.string   "name"
    t.integer  "cardset_id"
    t.string   "rarity"
    t.string   "cost"
    t.string   "supertype"
    t.string   "cardtype"
    t.string   "subtype"
    t.text     "rulestext"
    t.text     "flavourtext"
    t.string   "power"
    t.string   "toughness"
    t.string   "image"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "frame"
    t.string   "art_url"
    t.string   "artist"
    t.string   "image_url"
    t.integer  "last_edit_by"
    t.integer  "multipart"
    t.integer  "link_id"
    t.integer  "parent_id"
    t.string   "watermark"
    t.boolean  "colour_indicator"
    t.string   "colour"
    t.integer  "user_id"
  end

  add_index "cards", ["cardset_id"], name: "index_cards_on_cardset_id"
  add_index "cards", ["user_id"], name: "index_cards_on_user_id"

  create_table "cardsets", force: true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "last_edit_by"
    t.integer  "last_edit_log_id"
  end

  create_table "comments", force: true do |t|
    t.integer  "card_id"
    t.text     "user_name"
    t.datetime "posttime"
    t.text     "body"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cardset_id"
    t.integer  "user_id"
  end

  add_index "comments", ["card_id"], name: "index_comments_on_card_id"
  add_index "comments", ["cardset_id"], name: "index_comments_on_cardset_id"
  add_index "comments", ["user_id"], name: "index_comments_on_user_id"

  create_table "configurations", force: true do |t|
    t.string   "frame"
    t.boolean  "use_highlighting"
    t.boolean  "use_addressing"
    t.string   "default_comment_state"
    t.boolean  "cardlist_show_comments"
    t.boolean  "cardlist_show_code"
    t.boolean  "cardlist_show_active"
    t.boolean  "card_show_code"
    t.boolean  "card_show_active"
    t.string   "visibility"
    t.string   "commentability"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cardset_id"
    t.string   "editability"
    t.string   "adminability"
    t.integer  "last_edit_by"
    t.string   "border_colour"
    t.string   "admins"
  end

  create_table "deck_cards", force: true do |t|
    t.integer "card_id"
    t.integer "decklist_id"
    t.integer "count"
    t.integer "status"
    t.string  "section"
  end

  add_index "deck_cards", ["card_id"], name: "index_deck_cards_on_card_id"
  add_index "deck_cards", ["decklist_id"], name: "index_deck_cards_on_decklist_id"

  create_table "deck_wizards_cards", force: true do |t|
    t.integer  "gatherer_id"
    t.integer  "decklist_id"
    t.string   "section"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  add_index "deck_wizards_cards", ["decklist_id"], name: "index_deck_wizards_cards_on_decklist_id"

  create_table "decklists", force: true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "cardset_id"
    t.integer  "status"
    t.text     "stats"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  add_index "decklists", ["cardset_id"], name: "index_decklists_on_cardset_id"
  add_index "decklists", ["user_id"], name: "index_decklists_on_user_id"

  create_table "details_pages", force: true do |t|
    t.integer  "cardset_id"
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order"
    t.integer  "last_edit_by"
  end

  add_index "details_pages", ["cardset_id"], name: "index_details_pages_on_cardset_id"

  create_table "global_states", force: true do |t|
    t.integer  "singletonguard"
    t.datetime "lastedit"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "global_states", ["singletonguard"], name: "index_global_states_on_singletonguard", unique: true

  create_table "glyphs", force: true do |t|
    t.string   "string"
    t.integer  "cardset_id"
    t.string   "url"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "glyphs", ["cardset_id"], name: "index_glyphs_on_cardset_id"

  create_table "last_edit_logs", force: true do |t|
    t.integer  "cardset_id"
    t.datetime "datestamp"
    t.integer  "kind"
    t.integer  "user_id"
    t.integer  "object_id"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "last_edit_logs", ["cardset_id"], name: "index_last_edit_logs_on_cardset_id"
  add_index "last_edit_logs", ["datestamp"], name: "index_last_edit_logs_on_datestamp"

  create_table "logs", force: true do |t|
    t.integer  "cardset_id"
    t.datetime "datestamp"
    t.integer  "kind"
    t.integer  "user_id"
    t.integer  "object_id"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "logs", ["cardset_id"], name: "index_logs_on_cardset_id"
  add_index "logs", ["datestamp"], name: "index_logs_on_datestamp"
  add_index "logs", ["kind"], name: "index_logs_on_kind"
  add_index "logs", ["object_id"], name: "index_logs_on_object_id"

  create_table "mechanics", force: true do |t|
    t.string   "name"
    t.integer  "cardset_id"
    t.string   "codename"
    t.text     "reminder"
    t.integer  "parameters"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mechanics", ["cardset_id"], name: "index_mechanics_on_cardset_id"

  create_table "news_lists", force: true do |t|
    t.integer  "cardset_id"
    t.datetime "datestamp"
    t.string   "log_ids"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "news_lists", ["cardset_id"], name: "index_news_lists_on_cardset_id"

  create_table "old_cards", force: true do |t|
    t.integer  "card_id"
    t.string   "name"
    t.integer  "cardset_id"
    t.string   "colour"
    t.string   "rarity"
    t.string   "cost"
    t.string   "supertype"
    t.string   "cardtype"
    t.string   "subtype"
    t.text     "rulestext"
    t.text     "flavourtext"
    t.integer  "power"
    t.integer  "toughness"
    t.datetime "posttime"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at"

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password"
    t.string   "salt"
    t.boolean  "admin",              default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["name"], name: "index_users_on_name"

end
