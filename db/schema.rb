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

ActiveRecord::Schema.define(version: 2025_04_26_042656) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "forms", force: :cascade do |t|
    t.string "form_name"
    t.string "playlist_id"
    t.date "deadline"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_id"
    t.string "form_key"
    t.index ["user_id"], name: "index_forms_on_user_id"
  end

  create_table "requests", force: :cascade do |t|
    t.string "form_id"
    t.string "user_name"
    t.string "track_name"
    t.string "track_artists"
    t.string "track_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "nick_name"
    t.string "mail", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "spotify_uid"
    t.string "spotify_access_token"
    t.string "spotify_refresh_token"
    t.datetime "spotify_expires_at"
    t.index ["mail"], name: "index_users_on_mail", unique: true
  end

end
