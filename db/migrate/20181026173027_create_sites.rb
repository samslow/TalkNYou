class CreateSites < ActiveRecord::Migration[5.0]
  def change
    create_table :sites do |t|
      t.belongs_to :user, foreign_key: true
      t.string :site_name
      
      t.timestamps
    end
  end
end
