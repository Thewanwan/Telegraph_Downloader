# Telegraph 画像ダウンローダー

Flutter で構築されたクロスプラットフォームのデスクトップ＆モバイルツールで、`telegra.ph` に公開された画像アルバムを一括ダウンロードします。

![](images.png)

## 対応プラットフォーム

| プラットフォーム | 形式 | ステータス |
|------------------|------|------------|
| Android | APK | ✅ GitHub Actions で自動ビルド |
| iOS | IPA | ✅ GitHub Actions で自動ビルド |
| macOS | DMG | ✅ GitHub Actions で自動ビルド |
| Windows | EXE | ✅ GitHub Actions で自動ビルド |
| Linux | DEB / AppImage | ✅ GitHub Actions で自動ビルド |

## 機能

- **マルチスレッド一括ダウンロード** — 複数リンクの同時ダウンロード対応、スレッド数のカスタマイズ (2〜20)
- **フォーマット変換** — オリジナル、JPG、PNG、WebP、BMP 形式でエクスポート対応
- **ダーク/ライトテーマ** — ワンクリック切り替え、設定の自動記憶
- **ダウンロード履歴** — 最近の100件のダウンロード記録を自動保存
- **リアルタイム進捗** — 各アルバムのダウンロード状況と進捗を表示
- **自動リトライ** — ネットワーク不安定時のリトライ機構を内蔵
- **設定の永続化** — 全設定を自動保存し、次回起動時に自動復元

## 使い方

### ソースから実行

```bash
# Flutter SDK インストール: https://docs.flutter.dev/get-started/install
flutter pub get
flutter run
```

### リリース版をダウンロード

[Releases](https://github.com/Thewanwan/Telegraph_Downloader) ページからプラットフォーム対応のインストーラーをダウンロードしてください。

## 開発

### プロジェクト構造

```
lib/
├── main.dart                    # エントリポイント
└── src/
    ├── models/
    │   ├── download_config.dart   # ダウンロード設定モデル
    │   ├── album_progress.dart    # 進捗モデル
    │   └── download_result.dart   # 結果モデル
    ├── services/
    │   ├── network_service.dart   # ネットワークリクエストサービス
    │   ├── page_parser.dart       # ページパーサーサービス
    │   ├── config_service.dart    # 設定管理サービス
    │   └── download_service.dart  # ダウンロード管理サービス
    ├── screens/
    │   └── home_screen.dart       # メイン画面
    ├── widgets/
    │   ├── url_input_card.dart    # URL 入力コンポーネント
    │   ├── progress_card.dart     # 進捗表示コンポーネント
    │   ├── log_card.dart          # ログコンポーネント
    │   └── settings_sheet.dart    # 設定パネル
    └── utils/
        └── formatters.dart        # フォーマットユーティリティ
.github/workflows/
├── build-android.yml              # Android ビルド
├── build-ios.yml                  # iOS ビルド
├── build-macos.yml                # macOS ビルド
├── build-windows.yml              # Windows ビルド
├── build-linux.yml                # Linux ビルド
└── ci.yml                         # CI パイプライン
```

### ローカルビルド

```bash
# Android
flutter build apk --release --split-per-abi

# iOS (macOS + Xcode が必要)
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

## キーボードショートカット

| ショートカット | 機能 |
|----------------|------|
| `Ctrl+V` | リンクを入力欄に貼り付け |
| `Ctrl+Enter` | ダウンロード開始 |

## ネットワークに関する注意

`telegra.ph` にアクセスするにはプロキシが必要です。

- **モバイル**: プロキシ対応のネットワーク環境をご利用ください
- **デスクトップ**: グローバルプロキシを有効にするか、`natapp` などの転送ツールをご利用ください

## ライセンス

[GNU General Public License v3.0](LICENSE)
