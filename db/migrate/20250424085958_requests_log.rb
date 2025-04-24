class RequestsLog < ActiveRecord::Migration[6.1]
  def change
    create_table :requests do |t|
      t.string :form_id
      t.string :user_name
      t.string :track_name
      t.string :track_artists
      t.string :track_id
      t.timestamps
    end
  end
end
