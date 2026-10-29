#!/bin/bash
# Build rồi cài GoViet vào ~/Library/Input Methods
set -euo pipefail
cd "$(dirname "$0")"

./build.sh

DEST="$HOME/Library/Input Methods"
mkdir -p "$DEST"

# Tắt bản đang chạy (nếu có) để nạp bản mới
pkill -x GoViet 2>/dev/null || true

rm -rf "$DEST/GoViet.app"
cp -R build/GoViet.app "$DEST/"
echo "==> Đã cài vào $DEST/GoViet.app"

"$DEST/GoViet.app/Contents/MacOS/GoViet" --register || true

cat <<'MSG'

Bước tiếp theo:
  1. Mở Cài đặt Hệ thống → Bàn phím → Nguồn đầu vào → Sửa…
  2. Nếu chưa thấy GoViet: bấm "+", chọn Tiếng Việt → GoViet → Thêm.
     (Nếu vẫn không có, đăng xuất rồi đăng nhập lại một lần.)
  3. Chọn GoViet trên thanh menu và gõ thử: hoaf → hòa, thuys → thúy.
  Đổi kiểu đặt dấu cũ/mới trong menu nguồn nhập khi đang dùng GoViet.
MSG
