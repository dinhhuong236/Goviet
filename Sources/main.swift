// main.swift — khởi động server InputMethodKit.
// Chạy với tham số --register để đăng ký và bật bộ gõ ngay (không cần đăng xuất).

import Cocoa
import Carbon
import InputMethodKit

if CommandLine.arguments.contains("--register") {
    let url = Bundle.main.bundleURL as CFURL
    let status = TISRegisterInputSource(url)
    print(status == noErr ? "Đã đăng ký bộ gõ." : "TISRegisterInputSource lỗi \(status)")

    let filter = [kTISPropertyBundleID as String: Bundle.main.bundleIdentifier ?? ""] as CFDictionary
    if let list = TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource] {
        for source in list {
            let err = TISEnableInputSource(source)
            print(err == noErr ? "Đã bật GoViet trong danh sách nguồn nhập." : "TISEnableInputSource lỗi \(err)")
        }
        if list.isEmpty { print("Chưa thấy GoViet — hãy thêm thủ công trong Cài đặt Hệ thống.") }
    }
    exit(0)
}

let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String ?? "GoViet_Connection"
let server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier)
_ = server
NSApplication.shared.run()
