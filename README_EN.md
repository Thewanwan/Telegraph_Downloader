# Telegraph Image Downloader

A cross-platform desktop & mobile tool built with Flutter that batch downloads image albums published on `telegra.ph`.

![](images.png)

## Supported Platforms

| Platform | Format | Status |
|----------|--------|--------|
| Android | APK | ✅ Auto-built via GitHub Actions |
| iOS | IPA | ✅ Auto-built via GitHub Actions |
| macOS | DMG | ✅ Auto-built via GitHub Actions |
| Windows | EXE | ✅ Auto-built via GitHub Actions |
| Linux | DEB / AppImage | ✅ Auto-built via GitHub Actions |

## Features

- **Multithreaded batch download** — Download multiple links simultaneously, configurable thread count (2~20)
- **Format conversion** — Export as original format, JPG, PNG, WebP, or BMP
- **Dark/Light theme** — One-click toggle with auto-remembered preference
- **Download history** — Automatically saves the last 100 download records
- **Real-time progress** — View download status and progress for each album
- **Auto retry** — Built-in retry mechanism for unstable networks
- **Persistent config** — All settings auto-saved and restored on next launch

## Usage

### Run from source

```bash
# Install Flutter SDK: https://docs.flutter.dev/get-started/install
flutter pub get
flutter run
```

### Download prebuilt releases

Visit the [Releases](https://github.com/Thewanwan/Telegraph_Downloader/releases) page to download the installer for your platform.

## Development

### Project Structure

```
lib/
├── main.dart                    # Entry point
└── src/
    ├── models/
    │   ├── download_config.dart   # Download config model
    │   ├── album_progress.dart    # Progress model
    │   └── download_result.dart   # Result model
    ├── services/
    │   ├── network_service.dart   # Network request service
    │   ├── page_parser.dart       # Page parser service
    │   ├── config_service.dart    # Config management service
    │   └── download_service.dart  # Download management service
    ├── screens/
    │   └── home_screen.dart       # Main screen
    ├── widgets/
    │   ├── url_input_card.dart    # URL input component
    │   ├── progress_card.dart     # Progress display component
    │   ├── log_card.dart          # Log component
    │   └── settings_sheet.dart    # Settings panel
    └── utils/
        └── formatters.dart        # Formatting utilities
.github/workflows/
├── build-android.yml              # Android build
├── build-ios.yml                  # iOS build
├── build-macos.yml                # macOS build
├── build-windows.yml              # Windows build
├── build-linux.yml                # Linux build
└── ci.yml                         # CI pipeline
```

### Local Build

```bash
# Android
flutter build apk --release --split-per-abi

# iOS (requires macOS + Xcode)
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+V` | Paste links into input field |
| `Ctrl+Enter` | Start download |

## Network Notes

`telegra.ph` requires a proxy to access in certain regions.

- **Mobile**: Use a network environment that supports proxy
- **Desktop**: Enable global proxy or use tools like `natapp` for traffic forwarding

## License

[GNU General Public License v3.0](LICENSE)
