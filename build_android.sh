#!/bin/bash
echo "========================================"
echo " Telegraph Downloader Android 打包脚本"
echo "========================================"
echo
echo "[!] 注意: Android 打包需要以下环境:"
echo "    - Python 3.8+"
echo "    - Android SDK / NDK"
echo "    - Buildozer (pip install buildozer)"
echo
echo "推荐方式: 使用 Google Colab 或 Linux 服务器"
echo "详细文档: https://buildozer.readthedocs.io/"
echo

if ! command -v buildozer &> /dev/null; then
    echo "[!] 正在安装 Buildozer..."
    pip install buildozer
fi

echo "[*] 创建 buildozer 配置..."

cat > buildozer.spec << 'EOF'
[app]

title = Telegraph Downloader
package.name = telegraphdownloader
package.domain = org.telegraph

source.dir = .
source.include_exts = py,png,jpg,kv,atlas
version = 1.0

requirements = python3,customtkinter,requests,beautifulsoup4,pillow,urllib3

orientation = portrait

fullscreen = 0

android.permissions = INTERNET,WRITE_EXTERNAL_STORAGE,READ_EXTERNAL_STORAGE

android.api = 31
android.minapi = 24
android.ndk = 25b
android.sdk = 33
android.accept_sdk_license = True

# buildozer 会自动处理打包
EOF

echo "[*] 开始构建 APK..."
echo "    这可能需要 30-60 分钟..."
buildozer android debug

echo
if [ -f "bin/*.apk" ]; then
    echo "[✓] APK 构建完成!"
    cp bin/*.apk dist/TelegraphDownloader.apk 2>/dev/null
else
    echo "[!] 构建可能失败，请检查错误信息"
fi
