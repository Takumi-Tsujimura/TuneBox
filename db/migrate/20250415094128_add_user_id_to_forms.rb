class AddUserIdToForms < ActiveRecord::Migration[6.1]
  def change
    add_column :forms, :user_id, :integer
    add_index :forms, :user_id
  end
end
