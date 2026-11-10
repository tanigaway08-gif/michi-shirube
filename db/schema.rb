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

ActiveRecord::Schema[8.0].define(version: 2026_11_09_224429) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "schedules", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.string "start_time", null: false
    t.string "place_name", null: false
    t.text "content"
    t.integer "day_number", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_id"], name: "index_schedules_on_trip_id"
  end

  create_table "trips", force: :cascade do |t|
    t.integer "duration", null: false
    t.integer "budget", null: false
    t.string "departure", null: false
    t.integer "transport", null: false
    t.integer "companion", null: false
    t.string "title", null: false
    t.integer "prefecture", null: false
    t.text "description"
    t.integer "estimated_cost"
    t.string "share_token", null: false
    t.string "extra_conditions"
    t.boolean "is_visited", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["share_token"], name: "index_trips_on_share_token", unique: true
  end

  add_foreign_key "schedules", "trips"
end
