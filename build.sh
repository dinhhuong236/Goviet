#!/bin/bash
# Build GoViet.app (cần Xcode hoặc Command Line Tools: xcode-select --install)
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v swiftc >/dev/null; then
    echo "Không tìm thấy swiftc. Cài Command Line Tools bằng lệnh: xcode-select --install"
    exit 1
fi

mkdir -p build

echo "==> Chạy test bộ chuyển Telex"
swiftc -O Sources/TelexEngine.swift Tests/main.swift -o build/engine-tests
build/engine-tests Tests/cases.tsv

echo "==> Build GoViet.app"
APP=build/GoViet.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -target "$(uname -m)-apple-macos11" \
    Sources/main.swift Sources/InputController.swift Sources/TelexEngine.swift \
    -framework Cocoa -framework Carbon -framework InputMethodKit \
    -o "$APP/Contents/MacOS/GoViet"

cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/icon.tiff "$APP/Contents/Resources/icon.tiff"

# Ký ad-hoc (bắt buộc trên máy Apple Silicon)
codesign --force --sign - "$APP"

echo "==> Xong: $APP"
