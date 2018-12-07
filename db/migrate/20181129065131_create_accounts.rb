class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.belongs_to :site, foreign_key: true
      t.string :ID_name
      t.string :PW
      t.string :memo

      t.timestamps
    end
  end
end
