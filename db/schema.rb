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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101122224800) do

  create_table "cards", :force => true do |t|
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
    t.integer  "power"
    t.integer  "toughness"
    t.string   "image"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "frame"
    t.string   "art_url"
    t.string   "artist"
    t.string   "image_url"
    t.integer  "last_edit_by"
  end

  add_index "cards", ["cardset_id"], :name => "index_cards_on_cardset_id"

  create_table "cardsets", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "last_edit_by"
  end

  create_table "comments", :force => true do |t|
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

  add_index "comments", ["card_id"], :name => "index_comments_on_card_id"
  add_index "comments", ["cardset_id"], :name => "index_comments_on_cardset_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "configurations", :force => true do |t|
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
  end

  create_table "details_pages", :force => true do |t|
    t.integer  "cardset_id"
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order"
    t.integer  "last_edit_by"
  end

  add_index "details_pages", ["cardset_id"], :name => "index_details_pages_on_cardset_id"

  create_table "old_cards", :force => true do |t|
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

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password"
    t.string   "salt"
    t.boolean  "admin",              :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["name"], :name => "index_users_on_name"

end
