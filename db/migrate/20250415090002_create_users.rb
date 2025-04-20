class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :nick_name
      t.string :mail, null: false
      t.string :password_digest, null: false
      t.timestamps
    end

    add_index :users, :mail, unique: true
  end
end
