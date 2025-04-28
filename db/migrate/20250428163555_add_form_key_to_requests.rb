class AddFormKeyToRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :requests, :form_key, :string
  end
end
