class AddGradeClassNumberToRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :requests, :grade, :string
    add_column :requests, :class, :string
    add_column :requests, :number, :string
  end
end
