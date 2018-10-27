class CreateSites < ActiveRecord::Migration[5.0]
  def change
    create_table :sites do |t|
      t.belongs_to :user, foreign_key: true
      t.string :sname
      t.string :sid, default: "아디 없음"
      t.string :spw, default: "비번 없음"
      
      t.timestamps
    end
  end
end
