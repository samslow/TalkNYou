class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :key
      t.integer :flag, default: 0
	
      t.string :str_1
      t.string :str_2
      t.string :str_3
      t.string :str_4
      t.string :str_5

      t.timestamps
    end
  end
end
