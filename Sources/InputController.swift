// InputController.swift — cầu nối giữa InputMethodKit và TelexEngine.
// Chữ đang gõ được hiển thị dưới dạng "marked text" (giống bộ gõ của Apple),
// không giả lập phím Backspace, nên không bị lỗi mất/nhân đôi chữ trên Chrome, Electron…

import Cocoa
import InputMethodKit

enum Settings {
    private static let defaults = UserDefaults.standard
    static var oldStyle: Bool {
        get { defaults.object(forKey: "oldStyle") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "oldStyle") }
    }
    static var autoRestore: Bool {
        get { defaults.object(forKey: "autoRestore") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "autoRestore") }
    }
}

@objc(GoVietInputController)
final class GoVietInputController: IMKInputController {
    private let engine = TelexEngine()

    private enum KeyCode {
        static let delete: UInt16 = 51
        static let escape: UInt16 = 53
    }

    override func recognizedEvents(_ sender: Any!) -> Int {
        Int(NSEvent.EventTypeMask.keyDown.rawValue)
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event = event, event.type == .keyDown,
              let client = sender as? IMKTextInput else { return false }

        engine.oldStyle = Settings.oldStyle

        // Phím tắt (⌘, ⌃, ⌥): chốt từ đang gõ rồi để ứng dụng xử lý.
        let flags = event.modifierFlags.intersection([.command, .control, .option])
        if !flags.isEmpty {
            commit(client)
            return false
        }

        switch event.keyCode {
        case KeyCode.delete:
            guard engine.isComposing else { return false }
            engine.backspace()
            updateMarkedText(client)
            return true
        case KeyCode.escape:
            guard engine.isComposing else { return false }
            client.insertText(engine.commitRaw(), replacementRange: Self.noRange)
            return true
        default:
            break
        }

        guard let chars = event.characters, chars.count == 1, let ch = chars.first,
              ch.isASCII, ch.isLetter else {
            // Dấu cách, số, dấu câu, Enter, phím mũi tên…: chốt từ rồi cho phím đi tiếp.
            commit(client)
            return false
        }

        engine.key(ch)
        updateMarkedText(client)
        return true
    }

    // MARK: - Marked text

    private static let noRange = NSRange(location: NSNotFound, length: 0)

    private func updateMarkedText(_ client: IMKTextInput) {
        let text = engine.render()
        client.setMarkedText(text,
                             selectionRange: NSRange(location: (text as NSString).length, length: 0),
                             replacementRange: Self.noRange)
    }

    private func commit(_ client: IMKTextInput) {
        guard engine.isComposing else { return }
        client.insertText(engine.commit(autoRestore: Settings.autoRestore), replacementRange: Self.noRange)
    }

    /// Hệ thống gọi khi người dùng click chuột chỗ khác, đổi ứng dụng…
    override func commitComposition(_ sender: Any!) {
        if let client = sender as? IMKTextInput { commit(client) }
    }

    override func deactivateServer(_ sender: Any!) {
        if let client = sender as? IMKTextInput { commit(client) }
        super.deactivateServer(sender)
    }

    // MARK: - Menu trên thanh menu

    override func menu() -> NSMenu! {
        let menu = NSMenu(title: "GoViet")

        let old = NSMenuItem(title: "Đặt dấu kiểu cũ: òa, khỏe, thúy", action: #selector(chooseOldStyle(_:)), keyEquivalent: "")
        old.state = Settings.oldStyle ? .on : .off
        menu.addItem(old)

        let new = NSMenuItem(title: "Đặt dấu kiểu mới: oà, khoẻ, thuý", action: #selector(chooseNewStyle(_:)), keyEquivalent: "")
        new.state = Settings.oldStyle ? .off : .on
        menu.addItem(new)

        menu.addItem(.separator())

        let restore = NSMenuItem(title: "Tự khôi phục từ gõ sai (vd: windows, book)", action: #selector(toggleAutoRestore(_:)), keyEquivalent: "")
        restore.state = Settings.autoRestore ? .on : .off
        menu.addItem(restore)

        return menu
    }

    @objc func chooseOldStyle(_ sender: Any?) { Settings.oldStyle = true }
    @objc func chooseNewStyle(_ sender: Any?) { Settings.oldStyle = false }
    @objc func toggleAutoRestore(_ sender: Any?) { Settings.autoRestore.toggle() }
}
