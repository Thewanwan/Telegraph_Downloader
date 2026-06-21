# Telegraph Downloader

[English](README_EN.md) | [日本語](README_JA.md) | [한국어](README_KO.md)

一个基于 Flutter 的跨平台工具，批量下载 `telegra.ph` 上发布的各种图册。支持 Android、iOS、macOS、Windows、Linux 五大平台，App 内自动更新。

## 功能特性

- **多线程批量下载** — 输入多个链接，可配置 2~20 线程并发下载
- **实时进度追踪** — 每个图册独立进度条，显示下载/失败/完成状态
- **下载日志** — 终端风格日志面板，实时滚动显示下载过程
- **暗色/亮色主题** — 一键切换，自动记忆偏好
- **下载历史** — 保存最近 30 条记录，支持一键重新下载
- **自定义保存路径** — 通过文件夹选择器自由设置保存位置
- **自动重试** — 网络不稳定时自动重试，支持指数退避
- **应用内更新** — 自动检测 GitHub Releases 新版本，一键下载安装
- **剪贴板检测** — 从浏览器复制链接后，打开 App 自动提示粘贴
- **配置持久化** — 所有设置自动保存，下次启动自动恢复

## 支持平台

| 平台 | 格式 | 构建方式 | 状态 |
|------|------|----------|------|
| Android | APK | GitHub Actions | ✅ 已完成 |
| iOS | IPA | GitHub Actions | ✅ 已完成 |
| macOS | DMG | GitHub Actions | ✅ 已完成 |
| Windows | EXE | GitHub Actions | ✅ 已完成 |
| Linux | DEB | GitHub Actions | ✅ 已完成 |

## 下载安装

前往 [Releases](https://github.com/Thewanwan/Telegraph_Downloader/releases) 页面下载对应平台的安装包。

### Android
下载 `telegraph_x.x.x.apk` 文件，安装时需允许"未知来源"。

### Windows
下载 `telegraph_downloader.exe`，双击运行即可。

### macOS
下载 `.dmg` 文件，拖入 Applications 文件夹。首次打开需在"系统设置 → 隐私与安全"中允许运行。

### Linux
下载 `.deb` 文件安装：
```bash
sudo dpkg -i telegraph-downloader_x.x.x_amd64.deb
```

## 使用方法

### 基本流程
1. 在输入框中粘贴 `telegra.ph` 链接（每行一个）
2. 点击「开始下载」
3. 等待下载完成，图片保存到指定目录

### 快捷操作
- **剪贴板检测**：从浏览器复制 telegra.ph 链接后打开 App，自动提示粘贴
- **重新下载**：在历史记录中点击下载图标，链接自动填入输入框
- **取消下载**：下载过程中点击「取消」按钮

### 设置选项
| 选项 | 说明 | 默认值 |
|------|------|--------|
| 保存路径 | 图片保存位置 | 外部存储/Downloads/TelegraphDownloader |
| 线程数 | 并发下载线程 | 8 |
| 请求超时 | 单次请求超时时间 | 15 秒 |
| 保存格式 | 图片导出格式 | 保持原样 |
| 图片质量 | JPG/WebP 压缩质量 | 95 |

## 从源码运行

### 环境要求
- Flutter SDK 3.24+
- Dart SDK 3.5+

### 安装步骤
```bash
# 克隆仓库
git clone https://github.com/Thewanwan/Telegraph_Downloader.git
cd Telegraph_Downloader

# 安装依赖
flutter pub get

# 运行（Android）
flutter run

# 运行（Windows）
flutter run -d windows

# 运行（macOS）
flutter run -d macos

# 运行（Linux）
flutter run -d linux
```

### 本地构建
```bash
# Android (单个通用 APK)
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

## 项目结构

```
lib/
├── main.dart                          # 应用入口 + 版本检查
├── app/
│   ├── models/
│   │   ├── download_config.dart       # 下载配置（线程数/超时/格式等）
│   │   ├── album_progress.dart        # 图册下载进度模型
│   │   └── download_result.dart       # 下载结果汇总
│   └── services/
│       ├── config_service.dart        # 配置管理（SharedPreferences）
│       ├── download_service.dart      # 下载核心（并发控制/信号量）
│       ├── network_service.dart       # HTTP 网络请求（重试/超时）
│       ├── page_parser.dart           # Telegraph 页面解析
│       └── update_service.dart        # 应用内更新（GitHub API）
├── pages/
│   └── home/
│       └── home_page.dart             # 主界面（输入/进度/日志/操作）
└── widgets/
    ├── url_input_card.dart            # URL 输入卡片
    ├── progress_card.dart             # 下载进度卡片
    ├── log_card.dart                  # 日志面板（自动滚动）
    ├── settings_sheet.dart            # 设置底部面板
    └── history_dialog.dart            # 下载历史弹窗

.github/workflows/
├── build-android.yml                  # Android APK 构建
├── build-ios.yml                      # iOS IPA 构建
├── build-macos.yml                    # macOS DMG 构建
├── build-windows.yml                  # Windows EXE 构建
├── build-linux.yml                    # Linux DEB 构建
├── publish.yml                        # 发布 Draft Release
└── ci.yml                             # 代码分析 + 测试
```

## 技术栈

| 技术 | 用途 |
|------|------|
| Flutter 3.24 | 跨平台 UI 框架 |
| Provider | 状态管理 |
| http | HTTP 网络请求 |
| html | Telegraph 页面解析 |
| path_provider | 跨平台文件路径 |
| shared_preferences | 本地配置持久化 |
| file_picker | 文件夹选择器 |
| open_file | 打开 APK 安装包 |

## 网络说明

`telegra.ph` 需要代理访问。

| 平台 | 解决方案 |
|------|----------|
| Android | 使用支持代理的 VPN 或 Wi-Fi |
| iOS | 使用支持代理的 VPN |
| Windows | 开启全局代理或使用 natapp 等转发工具 |
| macOS | 开启系统代理 |
| Linux | 配置 http_proxy 环境变量 |

## 开发指南

### 发布新版本
1. 修改 `pubspec.yaml` 中的 `version` 字段
2. 提交并推送到 `main` 分支
3. 创建 Git 标签并推送，自动触发所有平台构建：
```bash
git tag v1.1.0
git push origin v1.1.0
```
4. 构建完成后在 GitHub Releases 页面发布

### CI/CD
- 推送到 `main` 分支触发所有平台构建
- 推送 `v*` 标签触发构建 + 发布 Draft Release
- 手动触发：在 Actions 页面选择 workflow → Run workflow

## 许可证

[GNU General Public License v3.0](LICENSE)
