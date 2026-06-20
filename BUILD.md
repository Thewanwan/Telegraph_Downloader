# Telegraph Downloader 构建指南

## 已完成的打包

| 格式 | 文件 | 状态 |
|------|------|------|
| Linux 二进制 | `dist/TelegraphDownloader` | ✅ 已完成 (27MB) |
| .deb 包 | `dist/telegraph-downloader_1.0_amd64.deb` | ✅ 已完成 |

## 需要在对应平台执行的打包

### Windows .exe
```cmd
# 在 Windows 命令行中执行:
build_windows.bat
# 输出: dist\TelegraphDownloader.exe
```

### macOS .dmg
```bash
# 在 macOS 终端中执行:
chmod +x build_macos.sh
./build_macos.sh
# 输出: dist/TelegraphDownloader.dmg
```

### Android .apk
```bash
# 需要 Linux 环境 + Android SDK
chmod +x build_android.sh
./build_android.sh
# 输出: dist/TelegraphDownloader.apk
```

## 环境准备

```bash
# Python 依赖
pip install -r requirements.txt pyinstaller

# Linux deb 打包
sudo apt install dpkg-dev

# Android 打包
pip install buildozer
sudo apt install -y git zip unzip openjdk-17-jdk python3-pip autoconf libtool pkg-config zlib1g-dev libncurses5-dev libncursesw5-dev libtinfo5 cmake libffi-dev libssl-dev
```
