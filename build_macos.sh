#!/bin/bash
echo "========================================"
echo " Telegraph Downloader macOS 打包脚本"
echo "========================================"
echo

if ! command -v pyinstaller &> /dev/null; then
    echo "[!] 正在安装 PyInstaller..."
    pip install pyinstaller
fi

echo "[*] 正在打包 macOS 应用..."
pyinstaller --onefile --name "TelegraphDownloader" --windowed --clean --noconfirm Telegraph_downloader.py

APP_NAME="TelegraphDownloader.app"
echo "[*] 正在创建 .app 结构..."
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"
cp dist/TelegraphDownloader "$APP_NAME/Contents/MacOS/TelegraphDownloader"

cat > "$APP_NAME/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TelegraphDownloader</string>
    <key>CFBundleName</key>
    <string>Telegraph Downloader</string>
    <key>CFBundleDisplayName</key>
    <string>Telegraph Downloader</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "[*] 正在创建 .dmg..."
if command -v hdiutil &> /dev/null; then
    hdiutil create -volname "Telegraph Downloader" -srcfolder "$APP_NAME" -ov -format UDZO "dist/TelegraphDownloader.dmg"
    echo "[✓] DMG 创建完成: dist/TelegraphDownloader.dmg"
else
    echo "[!] hdiutil 不可用，请在 macOS 上运行此脚本"
    echo "    应用已打包为: $APP_NAME"
fi

rm -rf "$APP_NAME"
echo
echo "[✓] 完成!"
