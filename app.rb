require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'securerandom'
require 'uri'
require 'json'
require 'net/http'
require 'open-uri'
require 'base64'
require 'dotenv/load'
require 'cgi'
require './models'

enable :sessions
use Rack::MethodOverride


configure do
  # 環境変数の読み込みを行う
  Dotenv.load

  # 必要な環境変数が読み込まれているかチェックしたり、設定をここで行う
  set :client_id, ENV['CLIENT_ID']
  set :client_secret, ENV['CLIENT_SECRET']
  set :redirect_uri, ENV['REDIRECT_URI'] || 'http://localhost:8888/callback'
end

def refresh_user_access_token(user)
  return if user.spotify_refresh_token.nil?

  uri = URI('https://accounts.spotify.com/api/token')
  auth_header = "Basic #{Base64.strict_encode64("#{settings.client_id}:#{settings.client_secret}")}"

  req = Net::HTTP::Post.new(uri)
  req['Authorization'] = auth_header
  req['Content-Type'] = 'application/x-www-form-urlencoded'
  req.set_form_data(
    grant_type: 'refresh_token',
    refresh_token: user.spotify_refresh_token
  )

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  if res.is_a?(Net::HTTPSuccess)
    token_data = JSON.parse(res.body)
    
    user.assign_attributes(
      spotify_access_token: token_data['access_token'],
      spotify_expires_at: Time.now + token_data['expires_in'].to_i
    )
    success = user.save(validate: false)

    puts "[INFO] トークン更新: #{user.id} 成功=#{success}"
    puts "[ERROR] 更新失敗: #{user.errors.full_messages.join(', ')}" unless success
  else
    puts "[ERROR] Spotifyトークンの更新に失敗: #{res.code} #{res.body}"
  end
end


def refresh_access_token
  return if session[:refresh_token].nil?

  uri = URI('https://accounts.spotify.com/api/token')
  auth_header = "Basic #{Base64.strict_encode64("#{settings.client_id}:#{settings.client_secret}")}"

  req = Net::HTTP::Post.new(uri)
  req['Authorization'] = auth_header
  req['Content-Type'] = 'application/x-www-form-urlencoded'
  req.set_form_data(
    grant_type: 'refresh_token',
    refresh_token: session[:refresh_token]
  )

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

  if res.is_a?(Net::HTTPSuccess)
    token_data = JSON.parse(res.body)

    # セッションに反映
    session[:access_token] = token_data['access_token']
    session[:expires_in] = Time.now + token_data['expires_in'].to_i

    # ユーザー情報にも保存（データベース更新）
    user = User.find_by(id: session[:user_id])
    if user
      user.update(
        spotify_access_token: token_data['access_token'],
        spotify_expires_at: session[:expires_in]
      )
    end
  else
    puts "[ERROR] セッション用Spotifyトークンの更新失敗: #{res.code} #{res.body}"
  end
end


def ensure_valid_token
  if session[:expires_in] && Time.now > session[:expires_in]
    refresh_access_token
  end
end


def get_user_profile
  ensure_valid_token
  uri = URI('https://api.spotify.com/v1/me')
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{session[:access_token]}"

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  res.is_a?(Net::HTTPSuccess) ? JSON.parse(res.body) : nil
end

get '/auth' do
  state = SecureRandom.hex(8)
  session[:state] = state
  session[:user] = {id: 1, name: "test_user"}


  scope = 'user-read-private user-read-email playlist-modify-public playlist-modify-private'
  query_params = {
    response_type: 'code',
    client_id: settings.client_id,
    scope: scope,
    redirect_uri: settings.redirect_uri,
    state: state
  }

  redirect "https://accounts.spotify.com/authorize?" + URI.encode_www_form(query_params)
end

get '/callback' do
  code = params[:code]
  state = params[:state]
  return redirect '/' if state != session[:state]

  # アクセストークン取得
  uri = URI('https://accounts.spotify.com/api/token')
  auth_header = "Basic #{Base64.strict_encode64("#{settings.client_id}:#{settings.client_secret}")}"
  
  req = Net::HTTP::Post.new(uri)
  req['Authorization'] = auth_header
  req['Content-Type'] = 'application/x-www-form-urlencoded'
  req.set_form_data(
    grant_type: 'authorization_code',
    code: code,
    redirect_uri: settings.redirect_uri
  )
  
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  
  unless res.is_a?(Net::HTTPSuccess)
    puts "[ERROR] トークン取得失敗: #{res.code} #{res.body}"
    return redirect '/?error=token_fetch_failed'
  end
  
  token_data = JSON.parse(res.body)
  puts "[DEBUG] トークン取得成功: #{token_data}"
  
  access_token = token_data['access_token']
  refresh_token = token_data['refresh_token']
  expires_at = Time.now + token_data['expires_in'].to_i

  # Spotifyユーザー情報を取得
  profile_uri = URI('https://api.spotify.com/v1/me')
  profile_req = Net::HTTP::Get.new(profile_uri)
  profile_req['Authorization'] = "Bearer #{access_token}"
  profile_res = Net::HTTP.start(profile_uri.hostname, profile_uri.port, use_ssl: true) { |http| http.request(profile_req) }

  return redirect '/' unless profile_res.is_a?(Net::HTTPSuccess)
  spotify_user = JSON.parse(profile_res.body)
  spotify_uid = spotify_user['id']

  # 新規登録処理（セッションに signup_params があるとき）
  if session[:signup_params]
    signup = session.delete(:signup_params)

    user = User.new(
      first_name: signup[:first_name],
      last_name: signup[:last_name],
      nick_name: signup[:nick_name],
      mail: signup[:mail],
      password: signup[:password],
      spotify_uid: spotify_uid,
      spotify_access_token: access_token,
      spotify_refresh_token: refresh_token,
      spotify_expires_at: expires_at
    )

    if user.save
      session[:user_id] = user.id

      # Spotifyトークンをセッションに保存（ここが重要！）
      session[:access_token] = access_token
      session[:refresh_token] = refresh_token
      session[:expires_in] = expires_at

      redirect '/login_form'  # ← ここはあなたの希望通り維持
    else
      return "ユーザー登録に失敗しました: #{user.errors.full_messages.join(', ')}"
    end
  else
    # 既存ユーザーのSpotify連携処理（必要なら後で拡張）
    redirect '/admin'
  end
end



get '/' do
  erb :home
end

get '/form/:form_key' do
  @form = Form.find_by(form_key: params[:form_key])
  @success_message = session.delete(:success_message)
  
  today_deadline = Date.today - 1
  deadline = @form.deadline.to_date rescue nil

  if deadline && deadline <= today_deadline
    redirect '/admin'
  end

  erb :'users/show', layout: :'users/layout'
end

get '/search/:form_key' do
  @form = Form.find_by(form_key: params[:form_key])
  keyword = params[:keyword]
  return redirect "/form/\#{params[:form_key]}" if keyword.nil? || keyword.strip.empty?

  form_owner = @form.user
  refresh_user_access_token(form_owner) if form_owner.spotify_expires_at && form_owner.spotify_expires_at < Time.now

  token = form_owner.spotify_access_token
  return "このフォームの管理者がSpotifyにログインしていません" if token.nil? || token.empty?

  uri = URI("https://api.spotify.com/v1/search?" + URI.encode_www_form(q: keyword, type: 'track'))
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{token}"

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  return "Spotify APIエラー: \#{res.code} - \#{res.body}" unless res.is_a?(Net::HTTPSuccess)

  @items = JSON.parse(res.body)['tracks']['items']
  return "検索結果なし。" if @items.nil? || @items.empty?

  erb :'users/list', layout: :'users/layout'
end

get '/req_form' do
  erb :'users/req_form', layout: false
end

post '/submit_request/:form_key' do
  @form = Form.find_by(form_key: params[:form_key])
  user_name = params[:user_name]
  track_name = params[:track_name]
  track_artists = params[:track_artists]
  track_id = params[:track_id]
  
  return "エラー: トラックIDが指定されていません" if track_id.nil? || track_id.strip.empty?
  
  form_owner = @form.user
  refresh_user_access_token(form_owner) if form_owner.spotify_expires_at && form_owner.spotify_expires_at < Time.now
  
  token = form_owner.spotify_access_token
  return "エラー: このフォームの管理者がSpotifyにログインしていません" if token.nil? || token.empty?
  
  playlist_uri = URI("https://api.spotify.com/v1/playlists/#{@form.playlist_id}/tracks?fields=items(track(id)),next&limit=100")
  headers = { 'Authorization' => "Bearer #{token}" }
  
  duplicate_found = false
  loop do
    req = Net::HTTP::Get.new(playlist_uri, headers)
    res = Net::HTTP.start(playlist_uri.hostname, playlist_uri.port, use_ssl: true) { |http| http.request(req) }

    unless res.is_a?(Net::HTTPSuccess)
      return "Spotify APIエラー（取得失敗）: #{res.code} - #{res.body}"
    end

    body = JSON.parse(res.body)
    track_ids = body["items"].map { |item| item.dig("track", "id") }
    if track_ids.include?(track_id)
      duplicate_found = true
      break
    end

    next_url = body["next"]
    break unless next_url
    playlist_uri = URI(next_url)
  end

  if duplicate_found
    request = Request.create(
      form_id: @form.form_key.to_s,
      user_name: user_name,
      track_name: track_name,
      track_artists: track_artists,
      track_id: track_id
    )
    puts "=== リクエスト保存 ==="
    puts request.inspect
    session[:success_message] = "リクエストが完了しました"
    redirect "/form/#{params[:form_key]}"
  end

  # 追加処理
  uri = URI("https://api.spotify.com/v1/playlists/#{@form.playlist_id}/tracks")
  request_body = {
    "uris" => ["spotify:track:#{track_id}"],
    "position" => 0
  }.to_json

  req = Net::HTTP::Post.new(uri)
  req['Authorization'] = "Bearer #{token}"
  req['Content-Type'] = 'application/json'
  req.body = request_body

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

  if res.is_a?(Net::HTTPSuccess)
    request = Request.create(
      form_id: @form.form_key.to_s,
      user_name: user_name,
      track_name: track_name,
      track_artists: track_artists,
      track_id: track_id
    )
    puts "=== リクエスト保存 ==="
    puts request.inspect

    session[:success_message] = "リクエストが完了しました"
    redirect "/form/#{params[:form_key]}"
  else
    "Spotify APIエラー: #{res.code} - #{res.body}"
  end
end

get '/admin' do
  # @forms = Form.all
  access_token = session[:access_token]
  
  if session[:user_id].nil?
    redirect '/login_form'
  end
  
  @forms = Form.where(user_id: session[:user_id])
  erb :'admin/form_list', layout: :'admin/layout'
end

get '/form_templates/new' do
  ensure_valid_token  # トークンの有効性を確認・更新
  token = session[:access_token]

  if token.nil? || token.empty?
    return "エラー: Spotify API トークンが取得できていません。ログインしてください。"
  end

  uri = URI("https://api.spotify.com/v1/me/playlists")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{token}"

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

  if res.is_a?(Net::HTTPSuccess)
    begin
      @playlists = JSON.parse(res.body)["items"]
    rescue JSON::ParserError => e
      return "エラー: JSON のパースに失敗しました。レスポンス: #{res.body}"
    end
  else
    return "Spotify API エラー: #{res.code} - #{res.message} - #{res.body}"
  end

  erb :'admin/create_form', layout: :'admin/layout'
end


post '/form_templates' do
  user_id = session[:user_id]
  unless user_id
    redirect '/login_form'
  end

  form_name = params[:form_name]
  playlist_id = params[:playlist_id]
  deadline = params[:deadline]
  deadline = nil if deadline.nil? || deadline.strip.empty?

  form = Form.new(
    form_name: form_name,
    playlist_id: playlist_id,
    deadline: deadline,
    user_id: user_id
  )

  if form.save
    puts "=== フォーム作成成功 ==="
    puts "form_id: #{form.id}"
    puts "form_key(UUID): #{form.form_key}"
    redirect '/admin'
  else
    erb :error, locals: { message: "フォームの保存に失敗しました。" }
  end
end

get '/forms/:form_key/edit' do
  @form = Form.find_by(form_key: params[:form_key])
  
  ensure_valid_token  # トークンの有効性を確認・更新
  token = session[:access_token]

  if token.nil? || token.empty?
    return "エラー: Spotify API トークンが取得できていません。ログインしてください。"
  end

  uri = URI("https://api.spotify.com/v1/me/playlists")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{token}"

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

  if res.is_a?(Net::HTTPSuccess)
    begin
      @playlists = JSON.parse(res.body)["items"]
    rescue JSON::ParserError => e
      return "エラー: JSON のパースに失敗しました。レスポンス: #{res.body}"
    end
  else
    return "Spotify API エラー: #{res.code} - #{res.message} - #{res.body}"
  end
  
  erb :'admin/edit', layout: :'admin/layout'
end

patch '/forms/:form_key' do
  form = Form.find_by(form_key: params[:form_key])
  form.update(form_name: params[:form_name], playlist_id: params[:playlist_id], deadline: params[:deadline])
  redirect '/admin'
end

delete '/forms/:form_key' do
  form = Form.find_by(form_key: params[:form_key])
  halt 404, "フォームが見つかりません" unless form
    
  form.destroy
  redirect '/admin'
end

get '/login_form' do
  @notice = session.delete(:notice)
  erb :'admin/login_form', layout: :'admin/layout'
end

get '/logup_form' do
  erb :'admin/logup_form', layout: :'admin/layout'
end

post '/login' do
  user = User.find_by(mail: params[:mail])

  if user && user.authenticate(params[:password])
    session[:user_id] = user.id

    # ↓↓↓ ここを追加
    session[:access_token] = user.spotify_access_token
    session[:refresh_token] = user.spotify_refresh_token
    session[:expires_in] = user.spotify_expires_at

    redirect '/admin'
  else
    session[:notice] = "メールアドレスまたはパスワードが間違っています"
    redirect '/login_form'
  end
end


post '/auth_signup' do
  session[:signup_params] = {
    first_name: params[:first_name],
    last_name: params[:last_name],
    nick_name: params[:nick_name],
    mail: params[:mail],
    password: params[:password]
  }

  redirect '/auth'
end

post '/admin/delete_all_users' do
  User.delete_all
  Form.delete_all
  "全ユーザーを削除しました"
end

get '/request_log/:form_key' do
  @form = Form.find_by(form_key: params[:form_key])
  
  @requests = Request.where(form_id: @form.form_key).order(created_at: :desc)
  erb :'admin/request_log', layout: :'admin/layout'
end

post '/track_delete' do
  form_key = params[:form_id]
  track_id = params[:track_id]

  form = Form.find_by(form_key: form_key)
  playlist_id = form.playlist_id

  form_owner = form.user  # ← 修正ポイント
  refresh_user_access_token(form_owner) if form_owner.spotify_expires_at && form_owner.spotify_expires_at < Time.now

  token = form_owner.spotify_access_token
  return "エラー: このフォームの管理者がSpfotifyにログインしていません" if token.nil? || token.empty?

  uri = URI("https://api.spotify.com/v1/playlists/#{playlist_id}/tracks")

  request_body = {
    "tracks" => [
      { "uri" => "spotify:track:#{track_id}" }
    ]
  }.to_json

  req = Net::HTTP::Delete.new(uri)
  req['Authorization'] = "Bearer #{token}"
  req['Content-Type'] = 'application/json'
  req.body = request_body

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

  if res.is_a?(Net::HTTPSuccess)
    request = Request.find_by(form_id: form_key, track_id: track_id)
    request.destroy if request
    redirect "/request_log/#{form_key}"
  else
    "Spotify APIエラー: #{res.code} - #{res.body}"
  end
end
