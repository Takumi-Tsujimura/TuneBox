class RenameClassToClassNameInRequests < ActiveRecord::Migration[6.1]
  def change
    rename_column :requests, :class, :class_name
  end
end
