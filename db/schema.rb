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

ActiveRecord::Schema.define(version: 20190614074209) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["email"], name: "index_admins_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true, using: :btree
  end

  create_table "application_settings", force: :cascade do |t|
    t.integer "singleton_guard"
    t.text    "home_page"
    t.string  "email_welcome"
    t.string  "email_connect_to_network"
    t.string  "email_legendary_mail"
    t.string  "email_invitation_to_area"
    t.index ["singleton_guard"], name: "index_application_settings_on_singleton_guard", using: :btree
  end

  create_table "blacklists", force: :cascade do |t|
    t.integer "user_id"
    t.integer "target_id"
    t.index ["target_id"], name: "index_blacklists_on_target_id", using: :btree
    t.index ["user_id"], name: "index_blacklists_on_user_id", using: :btree
  end

  create_table "cities", force: :cascade do |t|
    t.string "google_place_id"
    t.string "name"
  end

  create_table "ckeditor_assets", force: :cascade do |t|
    t.string   "data_file_name",               null: false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.string   "data_fingerprint"
    t.string   "type",              limit: 30
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["type"], name: "index_ckeditor_assets_on_type", using: :btree
  end

  create_table "contacts", force: :cascade do |t|
    t.string   "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "deleted_messages", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "message_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_deleted_messages_on_message_id", using: :btree
    t.index ["user_id"], name: "index_deleted_messages_on_user_id", using: :btree
  end

  create_table "followed_messages", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "message_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean  "followed"
  end

  create_table "images", force: :cascade do |t|
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "message_id"
    t.string   "url"
    t.index ["message_id"], name: "index_images_on_message_id", using: :btree
  end

  create_table "legendary_likes", force: :cascade do |t|
    t.integer  "message_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_legendary_likes_on_message_id", using: :btree
    t.index ["user_id"], name: "index_legendary_likes_on_user_id", using: :btree
  end

  create_table "locked_messages", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "message_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "unlocked",   default: false
    t.index ["message_id"], name: "index_locked_messages_on_message_id", using: :btree
    t.index ["user_id"], name: "index_locked_messages_on_user_id", using: :btree
  end

  create_table "messages", force: :cascade do |t|
    t.text     "text"
    t.integer  "user_id"
    t.decimal  "lng"
    t.decimal  "lat"
    t.boolean  "undercover"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "legendary"
    t.integer  "likes_count",         default: 0
    t.boolean  "public",              default: true
    t.boolean  "locked",              default: false
    t.string   "password_hash"
    t.string   "hint"
    t.string   "password_salt"
    t.boolean  "is_emoji",            default: false
    t.integer  "legendary_count",     default: 0
    t.string   "social"
    t.string   "url"
    t.string   "post_permalink"
    t.datetime "expire_date"
    t.integer  "points",              default: 0
    t.boolean  "deleted",             default: false
    t.integer  "post_code"
    t.string   "social_id"
    t.string   "messageable_type"
    t.integer  "messageable_id"
    t.string   "role_name"
    t.string   "place_name"
    t.string   "message_type"
    t.integer  "reply_count"
    t.string   "title"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "custom_line_id"
    t.index ["custom_line_id"], name: "index_messages_on_custom_line_id", using: :btree
    t.index ["messageable_type", "messageable_id"], name: "index_messages_on_messageable_type_and_messageable_id", using: :btree
    t.index ["user_id"], name: "index_messages_on_user_id", using: :btree
  end

  create_table "networks", force: :cascade do |t|
    t.integer  "post_code"
    t.string   "name"
    t.integer  "users_count"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "city_id"
    t.index ["city_id"], name: "index_networks_on_city_id", using: :btree
  end

  create_table "networks_users", force: :cascade do |t|
    t.integer "user_id"
    t.integer "network_id"
    t.boolean "invitation_sent",  default: false
    t.boolean "connected",        default: true
    t.date    "last_entrance_at"
    t.index ["network_id"], name: "index_networks_users_on_network_id", using: :btree
    t.index ["user_id"], name: "index_networks_users_on_user_id", using: :btree
  end

  create_table "posts", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "message"
    t.integer  "network_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "providers", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "token"
    t.string   "secret"
    t.string   "name"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "provider_id"
    t.index ["user_id"], name: "index_providers_on_user_id", using: :btree
  end

  create_table "replies", force: :cascade do |t|
    t.integer  "message_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "user_id"
    t.index ["message_id"], name: "index_replies_on_message_id", using: :btree
  end

  create_table "reports", force: :cascade do |t|
    t.integer  "reportable_id"
    t.string   "reportable_type"
    t.text     "reasons",         default: [],              array: true
    t.integer  "user_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["user_id"], name: "index_reports_on_user_id", using: :btree
  end

  create_table "rooms", force: :cascade do |t|
    t.integer  "message_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "users_count"
    t.index ["message_id"], name: "index_rooms_on_message_id", using: :btree
  end

  create_table "rooms_users", force: :cascade do |t|
    t.integer "room_id"
    t.integer "user_id"
    t.index ["room_id"], name: "index_rooms_users_on_room_id", using: :btree
    t.index ["user_id"], name: "index_rooms_users_on_user_id", using: :btree
  end

  create_table "subscribers", force: :cascade do |t|
    t.string   "email"
    t.string   "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "user_likes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "message_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_user_likes_on_message_id", using: :btree
    t.index ["user_id"], name: "index_user_likes_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                    default: "",    null: false
    t.string   "encrypted_password",       default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",            default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "auth_token"
    t.string   "phone"
    t.string   "first_name"
    t.string   "last_name"
    t.date     "date_of_birthday"
    t.string   "provider_id"
    t.string   "provider_name"
    t.boolean  "invitation_sent",          default: false
    t.string   "role_name"
    t.string   "role_description"
    t.string   "role_image_url"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "name"
    t.string   "hero_avatar_file_name"
    t.string   "hero_avatar_content_type"
    t.integer  "hero_avatar_file_size"
    t.datetime "hero_avatar_updated_at"
    t.integer  "gender"
    t.datetime "legendary_at"
    t.integer  "points_count",             default: 0
    t.boolean  "terms_of_use_accepted",    default: false
    t.string   "registration_id"
    t.index ["email"], name: "index_users_on_email", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "videos", force: :cascade do |t|
    t.string   "video_file_name"
    t.string   "video_content_type"
    t.integer  "video_file_size"
    t.datetime "video_updated_at"
    t.string   "url"
    t.integer  "message_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "thumbnail_url"
    t.index ["message_id"], name: "index_videos_on_message_id", using: :btree
  end

  add_foreign_key "replies", "messages"
  add_foreign_key "rooms", "messages"
end
