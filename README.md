# Telegraph 图片下载器

一个基于 Flutter 的跨平台桌面 & 移动端工具，支持批量下载 `telegra.ph` 上发布的各种图册。

![](images.png)

## 支持平台

| 平台 | 格式 | 状态 |
|------|------|------|
| Android | APK | ✅ GitHub Actions 自动构建 |
| iOS | IPA | ✅ GitHub Actions 自动构建 |
| macOS | DMG | ✅ GitHub Actions 自动构建 |
| Windows | EXE | ✅ GitHub Actions 自动构建 |
| Linux | DEB / AppImage | ✅ GitHub Actions 自动构建 |

## 功能特性

- **多线程批量下载** — 支持多链接同时下载，可自定义线程数 (2~20)
- **格式转换** — 支持保持原样、JPG、PNG、WebP、BMP 格式导出
- **暗色/亮色主题** — 一键切换，自动记忆偏好
- **下载历史** — 自动保存最近 100 条下载记录
- **实时进度** — 显示每个图册的下载状态和进度
- **自动重试** — 内置重试机制，应对网络不稳定
- **配置持久化** — 所有设置自动保存，下次启动自动恢复

## 使用方式

### 从源码运行

```bash
# 安装 Flutter SDK: https://docs.flutter.dev/get-started/install
flutter pub get
flutter run
```

### 下载预编译版本

前往 [Releases](https://github.com/Thewanwan/Telegraph_Downloader/releases) 页面下载对应平台的安装包。

## 开发

### 项目结构

```
lib/
├── main.dart                    # 入口
└── src/
    ├── models/
    │   ├── download_config.dart   # 下载配置模型
    │   ├── album_progress.dart    # 进度模型
    │   └── download_result.dart   # 结果模型
    ├── services/
    │   ├── network_service.dart   # 网络请求服务
    │   ├── page_parser.dart       # 页面解析服务
    │   ├── config_service.dart    # 配置管理服务
    │   └── download_service.dart  # 下载管理服务
    ├── screens/
    │   └── home_screen.dart       # 主界面
    ├── widgets/
    │   ├── url_input_card.dart    # URL 输入组件
    │   ├── progress_card.dart     # 进度显示组件
    │   ├── log_card.dart          # 日志组件
    │   └── settings_sheet.dart    # 设置面板
    └── utils/
        └── formatters.dart        # 格式化工具
.github/workflows/
├── build-android.yml              # Android 构建
├── build-ios.yml                  # iOS 构建
├── build-macos.yml                # macOS 构建
├── build-windows.yml              # Windows 构建
├── build-linux.yml                # Linux 构建
└── ci.yml                         # CI 流水线
```

### 本地构建

```bash
# Android
flutter build apk --release --split-per-abi

# iOS (需要 macOS + Xcode)
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+V` | 粘贴链接到输入框 |
| `Ctrl+Enter` | 开始下载 |

## 网络说明

国内网络环境复杂，`telegra.ph` 需要代理访问。

- **移动端**：使用支持代理的网络环境
- **桌面端**：开启全局代理或使用 `natapp` 等流量转发工具

## 许可证

[GNU General Public License v3.0](LICENSE)
