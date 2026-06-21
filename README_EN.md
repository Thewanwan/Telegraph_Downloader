# Telegraph Downloader

[中文](README.md) | [日本語](README_JA.md) | [한국어](README_KO.md)

A cross-platform Flutter tool for batch downloading image albums from `telegra.ph`. Supports Android, iOS, macOS, Windows, and Linux with in-app auto-update.

## Features

- **Multi-threaded batch download** — Enter multiple URLs, configure 2~20 concurrent threads
- **Real-time progress tracking** — Per-album progress bars with download/fail/complete status
- **Download log** — Terminal-style log panel with auto-scrolling
- **Dark/Light theme** — One-click toggle, preferences auto-saved
- **Download history** — Saves last 30 records, one-click re-download
- **Custom save path** — Choose any folder via file picker
- **Auto retry** — Automatic retry with exponential backoff on network errors
- **In-app update** — Auto-detect new releases from GitHub, download and install
- **Clipboard detection** — Auto-prompt to paste telegra.ph links when app resumes
- **Persistent config** — All settings saved, restored on next launch

## Supported Platforms

| Platform | Format | CI/CD | Status |
|----------|--------|-------|--------|
| Android | APK | GitHub Actions | ✅ Done |
| iOS | IPA | GitHub Actions | ✅ Done |
| macOS | DMG | GitHub Actions | ✅ Done |
| Windows | EXE | GitHub Actions | ✅ Done |
| Linux | DEB | GitHub Actions | ✅ Done |

## Download

Download from [Releases](https://github.com/Thewanwan/Telegraph_Downloader/releases).

### Android
Download `telegraph_x.x.x.apk`. Allow "Unknown sources" during installation.

### Windows
Download `telegraph_downloader.exe` and double-click to run.

### macOS
Download `.dmg`, drag to Applications. First launch: go to System Settings → Privacy & Security to allow.

### Linux
```bash
sudo dpkg -i telegraph-downloader_x.x.x_amd64.deb
```

## Usage

### Basic Workflow
1. Paste `telegra.ph` links in the input field (one per line)
2. Tap "开始下载" (Start Download)
3. Wait for completion — images saved to the configured directory

### Quick Actions
- **Clipboard detection**: Copy a telegra.ph link in browser, open app — auto-prompt to paste
- **Re-download**: Tap download icon in history — URLs auto-filled into input
- **Cancel**: Tap "取消" during download to stop

### Settings
| Option | Description | Default |
|--------|-------------|---------|
| Save Path | Image save location | External Storage/Downloads/TelegraphDownloader |
| Threads | Concurrent download threads | 8 |
| Timeout | Request timeout (seconds) | 15 |
| Format | Image export format | Original |
| Quality | JPG/WebP compression | 95 |

## Build from Source

### Requirements
- Flutter SDK 3.24+
- Dart SDK 3.5+

### Setup
```bash
git clone https://github.com/Thewanwan/Telegraph_Downloader.git
cd Telegraph_Downloader
flutter pub get
flutter run
```

### Build Commands
```bash
# Android (single universal APK)
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

## Project Structure

```
lib/
├── main.dart                          # Entry point + version check
├── app/
│   ├── models/
│   │   ├── download_config.dart       # Config (threads, timeout, format)
│   │   ├── album_progress.dart        # Album download progress
│   │   └── download_result.dart       # Download result summary
│   └── services/
│       ├── config_service.dart        # Config management (SharedPreferences)
│       ├── download_service.dart      # Core download engine (semaphore)
│       ├── network_service.dart       # HTTP client (retry, timeout)
│       ├── page_parser.dart           # Telegraph page parser
│       └── update_service.dart        # In-app update (GitHub API)
├── pages/home/
│   └── home_page.dart                 # Main screen
└── widgets/                           # UI components
```

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter 3.24 | Cross-platform UI |
| Provider | State management |
| http | HTTP networking |
| html | Page parsing |
| path_provider | File path resolution |
| shared_preferences | Local config storage |
| file_picker | Folder picker |
| open_file | Open APK installer |

## Network Notes

`telegra.ph` requires a proxy to access in most regions.

| Platform | Solution |
|----------|----------|
| Android | Use a VPN or proxy-enabled Wi-Fi |
| iOS | Use a VPN with proxy support |
| Windows | Enable global proxy or use tunnel tools like natapp |
| macOS | Enable system proxy |
| Linux | Set `http_proxy` environment variable |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push and create a Pull Request

## License

[GNU General Public License v3.0](LICENSE)
