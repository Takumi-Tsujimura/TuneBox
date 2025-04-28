class AddFormTypeToForms < ActiveRecord::Migration[6.1]
  def change
     add_column :forms, :form_type, :string
  end
end
