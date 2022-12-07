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

ActiveRecord::Schema[7.0].define(version: 2022_12_04_053535) do
  create_table "albums", primary_key: "album_id", force: :cascade do |t|
    t.integer "singer_id", limit: 8, null: false
    t.string "title"
    t.time "created_at", null: false
    t.time "updated_at", null: false
  end

  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.string "tags", null: false
    t.string "ratings", null: false
    t.time "created_at", null: false
    t.time "updated_at", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.integer "post_id", limit: 8, null: false
    t.string "text"
    t.time "created_at", null: false
    t.time "updated_at", null: false
  end

  create_table "posts", force: :cascade do |t|
    t.string "text"
    t.time "created_at", null: false
    t.time "updated_at", null: false
  end

  create_table "singers", primary_key: "singer_id", force: :cascade do |t|
    t.string "name"
    t.time "created_at", null: false
    t.time "updated_at", null: false
  end

  create_table "tracks", primary_key: "track_id", force: :cascade do |t|
    t.integer "singer_id", limit: 8, null: false
    t.integer "album_id", limit: 8, null: false
    t.string "title"
    t.time "created_at", null: false
    t.time "updated_at", null: false
  end

  add_foreign_key "comments", "posts"
end
