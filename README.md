# GoViet — bộ gõ Telex cho macOS, đặt dấu kiểu cũ (òa, khỏe, thúy)

Bộ gõ viết bằng InputMethodKit. Chữ đang gõ hiện dưới dạng *marked text* (có gạch chân, giống bộ gõ của Apple) chứ không giả lập phím Backspace, nên không bị lỗi mất hoặc nhân đôi chữ (kiểu lỗi chữ "ý") trên Chrome, Safari, VS Code, Slack…

## Cài đặt

Cần Xcode hoặc Command Line Tools (`xcode-select --install`).

```bash
cd GoViet
chmod +x *.sh
./install.sh
```

Script sẽ chạy test, build `GoViet.app`, chép vào `~/Library/Input Methods` và đăng ký bộ gõ. Sau đó:

1. **Cài đặt Hệ thống → Bàn phím → Nguồn đầu vào → Sửa…**
2. Nếu chưa thấy GoViet: bấm **+** → **Tiếng Việt** → **GoViet** → **Thêm**. Nếu vẫn không có, đăng xuất rồi đăng nhập lại một lần.
3. Chọn GoViet trên thanh menu. Nên bỏ bộ gõ tiếng Việt của Apple (và tắt OpenKey/EVKey) để khỏi đụng nhau.

Gỡ cài đặt: `./uninstall.sh`.

## Cách gõ (Telex)

| Gõ | Ra | Gõ | Ra |
|---|---|---|---|
| `aa` `ee` `oo` | â ê ô | `s` `f` `r` `x` `j` | sắc huyền hỏi ngã nặng |
| `aw` `ow` `uw` | ă ơ ư | `z` | xóa dấu |
| `uow` | ươ | `dd` | đ |
| `w` (đứng riêng) | ư | gõ lặp phím | hoàn tác (`ass` → as, `ww` → w) |

- Dấu có thể gõ ở giữa hoặc cuối từ, vị trí dấu tự sắp lại: `hoafn` = `hoanf` = hoàn.
- **Esc** khi đang gõ dở: chèn đúng các phím đã gõ, bỏ mọi biến đổi.
- **Tự khôi phục**: khi kết thúc từ, nếu kết quả không phải âm tiết tiếng Việt hợp lệ thì trả lại phím gốc (`windows`, `book`, `text` giữ nguyên). Từ tiếng Anh trùng âm tiết Việt hợp lệ vẫn bị đổi (`test` → tét); dùng Esc cho các trường hợp đó.

## Menu

Khi đang dùng GoViet, bấm vào biểu tượng nguồn nhập trên thanh menu:

- **Đặt dấu kiểu cũ: òa, khỏe, thúy** (mặc định)
- **Đặt dấu kiểu mới: oà, khoẻ, thuý**
- **Tự khôi phục từ gõ sai** (bật/tắt)

Khác biệt giữa hai kiểu chỉ ở vần **oa, oe, uy** không có phụ âm cuối. Các chữ như hoàn, toán, quà, của giống nhau ở cả hai kiểu.

## Cấu trúc

```
Sources/TelexEngine.swift      bộ chuyển phím Telex, không phụ thuộc AppKit
Sources/InputController.swift  cầu nối InputMethodKit, menu, cài đặt
Sources/main.swift             khởi động IMKServer; --register để đăng ký nhanh
Resources/Info.plist           khai báo bộ gõ
Tests/cases.tsv                test: kiểu dấu, phím gõ, kết quả mong đợi
Tests/main.swift               chạy test bằng Swift (build.sh tự chạy)
Tests/reference_engine.py      bản Python tương đương: python3 Tests/reference_engine.py Tests/cases.tsv
```

Muốn sửa quy tắc đặt dấu: xem `toneIndex()` trong `TelexEngine.swift`, thêm test vào `cases.tsv`.
