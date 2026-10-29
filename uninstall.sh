#!/bin/bash
# Gỡ GoViet
pkill -x GoViet 2>/dev/null || true
rm -rf "$HOME/Library/Input Methods/GoViet.app"
defaults delete com.dinhhuong.inputmethod.GoViet 2>/dev/null || true
echo "Đã gỡ GoViet. Đăng xuất rồi đăng nhập lại để nó biến khỏi danh sách nguồn nhập."
