# BGMリクエストフォーム / BGM Request Form

## 概要 / Overview

管理者はログインが必要です。
アカウント作成時に自身のSpotifyアカウントと連携することで、本アプリの機能を利用できるようになります。
管理者は、イベントごとにフォームを作成することができ、各フォームにはリクエストの受付期限や、追加先となるSpotifyプレイリストを設定できます。
ユーザーは、管理者から共有されたリンクにアクセスし、楽曲を検索してリクエストすることができます（ログイン不要）。

Administrators are required to log in.
By connecting their Spotify account during sign-up, they can access all the app’s features.
They can create individual request forms for each event, set submission deadlines, and specify the target Spotify playlist for adding tracks.
Users can access the shared link from the administrator to search for and request songs — no login required.

## 主な機能 / Features

- 管理者ログイン / Admin login
- フォームの作成と共有 / Form creation and sharing
- 楽曲リクエスト / Track requests
- Spotify API連携 / Spotify API integration

## 使用技術 / Technologies

- Sinatra (Ruby)
- SQLite3
- Spotify Web API
- HTML / CSS / JavaScript

## 環境変数の設定 / Environment Variables

このアプリを動かすには、以下の環境変数を `.env` ファイルに設定する必要があります。

- `CLIENT_ID`: Spotifyのアプリケーションで発行されるクライアントID  
- `CLIENT_SECRET`: Spotifyのアプリケーションで発行されるシークレットキー  
- `REDIRECT_URI`: Spotify認証後にリダイレクトされるURL（ローカル環境では `http://localhost:8888/callback` を使用してください）

`.env` ファイルは Git に含めず、自分だけが持っているようにしてください。

To run this app, you need to set the following environment variables in a `.env` file:

- `CLIENT_ID`: Your Spotify application's client ID  
- `CLIENT_SECRET`: Your Spotify application's secret key  
- `REDIRECT_URI`: The URL users are redirected to after Spotify authentication (use `http://localhost:8888/callback` for local development)

Do not include your `.env` file in Git. Keep it private.
