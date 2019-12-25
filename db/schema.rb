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

ActiveRecord::Schema.define(version: 20191222060009) do

  create_table "applies", force: :cascade do |t|
    t.integer "month"
    t.integer "apply_user_id"
    t.integer "approve_user_id"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "attendances", force: :cascade do |t|
    t.date "worked_on"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "note"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "apply_finished_at"
    t.string "overtime_reason"
    t.integer "overtime_approve_user_id"
    t.integer "approve_status"
    t.string "attendance_change_started_at"
    t.string "attendance_change_finished_at"
    t.integer "attendance_change_approve_user_id"
    t.integer "attendance_change_approve_status"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "bases", force: :cascade do |t|
    t.integer "baseNo"
    t.string "baseName"
    t.string "attendanceKind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "changes", force: :cascade do |t|
    t.integer "apply_user_id"
    t.string "date"
    t.string "before_started_at"
    t.string "before_finished_at"
    t.string "after_started_at"
    t.string "after_finished_at"
    t.string "note"
    t.integer "status"
    t.integer "approve_user_id"
    t.string "approve_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.boolean "admin", default: false
    t.string "affiliation"
    t.datetime "basic_time", default: "2019-02-19 22:30:00"
    t.datetime "work_time", default: "2019-02-19 23:00:00"
    t.integer "employee_number"
    t.string "uid"
    t.string "basic_work_time"
    t.string "designated_work_start_time"
    t.string "designated_work_end_time"
    t.boolean "superior", default: false
    t.integer "month_attendance_from_user_id"
    t.integer "months"
    t.integer "month_attendance_approve_status"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
