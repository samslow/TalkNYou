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

ActiveRecord::Schema.define(version: 20181026173027) do
#rake db:migrate:reset 을 통해 DB 초기화 & 마이그레이션 재작업
  create_table "accounts", force: :cascade do |t|
    t.integer  "site_id"
    t.string   "ID_name"
    t.string   "PW"
    t.string   "Memo"
  end
  
  create_table "sites", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "site_name"
  end  

  create_table "users", force: :cascade do |t|
    t.string   "key"
    t.integer  "flag",       default: 0 #기본 플래그는 0 -> 홈메뉴

	t.string  "str_1" #이 str_n 들은 사용자의 입력을 저장하는 용도
	t.string  "str_2"
	t.string  "str_3"
	t.string  "str_4"
	t.string  "str_5"
  end

end
