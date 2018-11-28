class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.belongs_to :site, foreign_key: true
      t.string :ID
      t.string :PW
      t.string :memo
      t.datetime :updated_date

      t.timestamps
    end
  end
end
