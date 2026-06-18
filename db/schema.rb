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

ActiveRecord::Schema[7.1].define(version: 2024_01_01_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "concentration_rules", force: :cascade do |t|
    t.string "scope_type", null: false
    t.string "scope_value"
    t.decimal "max_concentration_pct", precision: 5, scale: 4, null: false
    t.boolean "active", default: true, null: false
    t.date "effective_from"
    t.date "effective_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scope_type", "scope_value", "active"], name: "index_concentration_rules_on_scope_and_active"
  end

  create_table "loans", force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.string "state_code", limit: 2, null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state_code", "status"], name: "index_loans_on_state_code_and_status"
    t.index ["state_code"], name: "index_loans_on_state_code"
    t.index ["status"], name: "index_loans_on_status"
  end

end
