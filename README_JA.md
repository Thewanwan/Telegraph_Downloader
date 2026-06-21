# Telegraph Downloader

[中文](README.md) | [English](README_EN.md) | [한국어](README_KO.md)

`telegra.ph` に公開されている画像アルバムをバッチダウンロードするためのクロスプラットフォームツール。Android、iOS、macOS、Windows、Linux をサポートし、アプリ内自動更新機能を搭載。

## 機能

- **マルチスレッドバッチダウンロード** — 複数URL入力、2〜20並列スレッド設定
- **リアルタイム進捗追跡** — アルバムごとのプログレスバー、ダウンロード/失敗/完了ステータス表示
- **ダウンロードログ** — ターミナル風ログパネル、自動スクロール
- **ダーク/ライトテーマ** — ワンクリック切替、設定自動保存
- **ダウンロード履歴** — 直近30件保存、ワンクリック再ダウンロード
- **カスタム保存パス** — フォルダ選択器で自由に設定
- **自動リトライ** — 指数バックオフによる自動リトライ
- **アプリ内更新** — GitHub Releasesの新バージョンを自動検出、ワンクリックダウンロード＆インストール
- **クリップボード検出** — ブラウザからリンクコピー後、アプリ起動時に自動ペースト提案
- **設定永続化** — 全設定を自動保存、次回起動時に自動復元

## サポートプラットフォーム

| プラットフォーム | 形式 | CI/CD | ステータス |
|------------------|------|-------|------------|
| Android | APK | GitHub Actions | ✅ 完了 |
| iOS | IPA | GitHub Actions | ✅ 完了 |
| macOS | DMG | GitHub Actions | ✅ 完了 |
| Windows | EXE | GitHub Actions | ✅ 完了 |
| Linux | DEB | GitHub Actions | ✅ 完了 |

## ダウンロード

[Releases](https://github.com/Thewanwan/Telegraph_Downloader) からダウンロード。

### Android
`telegraph_x.x.x.apk` をダウンロード。「不明なソース」の許可が必要です。

### Windows
`telegraph_downloader.exe` をダウンロード、ダブルクリックで実行。

### macOS
`.dmg` をダウンロード、Applications にドラッグ。初回起動は「システム設定 → プライバシーとセキュリティ」で許可が必要です。

### Linux
```bash
sudo dpkg -i telegraph-downloader_x.x.x_amd64.deb
```

## 使い方

### 基本フロー
1. `telegra.ph` のリンクを入力欄に貼り付け（1行に1リンク）
2. 「ダウンロード開始」をタップ
3. 完了を待つ — 画像は指定ディレクトリに保存

### クイック操作
- **クリップボード検出**: ブラウザからtelegra.phリンクをコピーしてアプリを開くと、自動提案
- **再ダウンロード**: 履歴のダウンロードアイコンをタップ — リンクが自動入力
- **キャンセル**: ダウンロード中に「キャンセル」をタップ

### 設定オプション
| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| 保存パス | 画像保存先 | 外部ストレージ/Downloads/TelegraphDownloader |
| スレッド数 | 並列ダウンロード数 | 8 |
| タイムアウト | リクエストタイムアウト | 15秒 |
| 保存形式 | 画像エクスポート形式 | オリジナル |
| 品質 | JPG/WebP圧縮品質 | 95 |

## ソースからビルド

### 必要要件
- Flutter SDK 3.24+
- Dart SDK 3.5+

### セットアップ
```bash
git clone https://github.com/Thewanwan/Telegraph_Downloader.git
cd Telegraph_Downloader
flutter pub get
flutter run
```

### ビルドコマンド
```bash
# Android（ユニバーサルAPK）
flutter build apk --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

## プロジェクト構造

```
lib/
├── main.dart                          # エントリポイント + バージョンチェック
├── app/
│   ├── models/
│   │   ├── download_config.dart       # 設定（スレッド/タイムアウト/形式）
│   │   ├── album_progress.dart        # アルバム進捗モデル
│   │   └── download_result.dart       # ダウンロード結果サマリ
│   └── services/
│       ├── config_service.dart        # 設定管理（SharedPreferences）
│       ├── download_service.dart      # ダウンロードコア（セマフォ）
│       ├── network_service.dart       # HTTPクライアント（リトライ/タイムアウト）
│       ├── page_parser.dart           # Telegraphページパーサー
│       └── update_service.dart        # アプリ内更新（GitHub API）
├── pages/home/
│   └── home_page.dart                 # メイン画面
└── widgets/                           # UIコンポーネント
```

## 技術スタック

| 技術 | 用途 |
|------|------|
| Flutter 3.24 | クロスプラットフォームUI |
| Provider | 状態管理 |
| http | HTTP通信 |
| html | ページ解析 |
| path_provider | ファイルパス解決 |
| shared_preferences | ローカル設定保存 |
| file_picker | フォルダ選択 |
| open_file | APKインストーラ起動 |

## ネットワークについて

`telegra.ph` にアクセスするにはプロキシが必要です。

| プラットフォーム | 解決策 |
|------------------|--------|
| Android | VPNまたはプロキシ対応Wi-Fi |
| iOS | プロキシ対応VPN |
| Windows | グローバルプロキシまたはnatapp等の転送ツール |
| macOS | システムプロキシを有効化 |
| Linux | `http_proxy` 環境変数を設定 |

## ライセンス

[GNU General Public License v3.0](LICENSE)
