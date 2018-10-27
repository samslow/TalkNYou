class CreateSites < ActiveRecord::Migration[5.0]
  def change
    create_table :sites do |t|
      t.belongs_to :user, foreign_key: true
      t.string :sname
      t.string :sid
      t.string :spw
      
      t.timestamps
    end
  end
end
