class AddSpotifyDisplayNameToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :spotify_display_name, :string
  end
end
