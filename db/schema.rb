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

ActiveRecord::Schema[8.1].define(version: 2026_06_16_000000) do
  create_table "album_artists", force: :cascade do |t|
    t.integer "album_id", null: false
    t.integer "artist_id", null: false
    t.datetime "created_at", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["album_id", "position"], name: "index_album_artists_on_album_id_and_position", unique: true
    t.index ["album_id"], name: "index_album_artists_on_album_id"
    t.index ["artist_id"], name: "index_album_artists_on_artist_id"
  end

  create_table "albums", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "release_date"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "artists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "external_ids", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.integer "internal_id", null: false
    t.string "internal_type", null: false
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["internal_type", "internal_id", "provider"], name: "index_external_ids_on_internal_and_provider", unique: true
    t.index ["internal_type", "internal_id"], name: "index_external_ids_on_internal"
  end

  create_table "oauth_tokens", force: :cascade do |t|
    t.string "access_token", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "provider", null: false
    t.string "refresh_token", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "provider"], name: "index_oauth_tokens_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_oauth_tokens_on_user_id"
  end

  create_table "playlist_tracks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "playlist_id", null: false
    t.integer "position"
    t.integer "track_id", null: false
    t.datetime "updated_at", null: false
    t.index ["playlist_id", "position"], name: "index_playlist_tracks_on_playlist_id_and_position", unique: true
    t.index ["playlist_id"], name: "index_playlist_tracks_on_playlist_id"
    t.index ["track_id"], name: "index_playlist_tracks_on_track_id"
  end

  create_table "playlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "track_artists", force: :cascade do |t|
    t.integer "artist_id", null: false
    t.datetime "created_at", null: false
    t.integer "position"
    t.integer "track_id", null: false
    t.datetime "updated_at", null: false
    t.index ["artist_id"], name: "index_track_artists_on_artist_id"
    t.index ["track_id"], name: "index_track_artists_on_track_id"
  end

  create_table "tracks", force: :cascade do |t|
    t.integer "album_id", null: false
    t.datetime "created_at", null: false
    t.string "title"
    t.integer "track_number"
    t.datetime "updated_at", null: false
    t.index ["album_id"], name: "index_tracks_on_album_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "album_artists", "albums"
  add_foreign_key "album_artists", "artists"
  add_foreign_key "oauth_tokens", "users"
  add_foreign_key "playlist_tracks", "playlists"
  add_foreign_key "playlist_tracks", "tracks"
  add_foreign_key "sessions", "users"
  add_foreign_key "track_artists", "artists"
  add_foreign_key "track_artists", "tracks"
  add_foreign_key "tracks", "albums"
end
