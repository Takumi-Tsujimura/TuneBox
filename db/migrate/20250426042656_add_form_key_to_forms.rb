class AddFormKeyToForms < ActiveRecord::Migration[6.1]
  def change
    add_column :forms, :form_key, :string
  end
end
