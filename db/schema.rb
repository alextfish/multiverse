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

ActiveRecord::Schema.define(:version => 20100930004247) do

  create_table "cards", :force => true do |t|
    t.string   "code"
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
    t.string   "image"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cardsets", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :force => true do |t|
    t.integer  "card_id"
    t.text     "user"
    t.datetime "posttime"
    t.text     "comment"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["card_id"], :name => "index_comments_on_card_id"

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

end
