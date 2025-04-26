require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection

class Form < ActiveRecord::Base
  before_create do
    self.form_key = SecureRandom.uuid
  end
  belongs_to :user

  validates :form_name, presence: true
  validates :playlist_id, presence: true
end

class User < ActiveRecord::Base
  has_secure_password
  has_many :forms

  validates :mail, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }
  
  # Spotify連携用のカラム（必要に応じてバリデーション追加もOK）
  # spotify_uid :string
  # spotify_access_token :string
  # spotify_refresh_token :string
  # spotify_expires_at :datetime
end

class Request < ActiveRecord::Base
  
end