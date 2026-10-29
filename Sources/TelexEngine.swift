// TelexEngine.swift — bộ chuyển phím Telex, không phụ thuộc AppKit (test được độc lập).
// Thuật toán giống hệt Tests/reference_engine.py.

import Foundation

final class TelexEngine {
    enum Mod { case none, hat, breve, horn, stroke }

    struct Letter {
        var base: Character      // chữ thường ASCII
        var upper: Bool
        var mod: Mod = .none
        var fromW: Bool = false  // "ư" sinh ra từ phím w đứng riêng

        var plain: Character {
            switch (base, mod) {
            case ("a", .hat): return "â"
            case ("a", .breve): return "ă"
            case ("e", .hat): return "ê"
            case ("o", .hat): return "ô"
            case ("o", .horn): return "ơ"
            case ("u", .horn): return "ư"
            case ("d", .stroke): return "đ"
            default: return base
            }
        }
    }

    // MARK: - Bảng dữ liệu

    private static let vowels: Set<Character> = ["a", "e", "i", "o", "u", "y"]
    private static let vnVowels: Set<Character> = Set("aăâeêioôơuưy")
    /// thứ tự: sắc, huyền, hỏi, ngã, nặng
    private static let toned: [Character: [Character]] = [
        "a": Array("áàảãạ"), "ă": Array("ắằẳẵặ"), "â": Array("ấầẩẫậ"),
        "e": Array("éèẻẽẹ"), "ê": Array("ếềểễệ"), "i": Array("íìỉĩị"),
        "o": Array("óòỏõọ"), "ô": Array("ốồổỗộ"), "ơ": Array("ớờởỡợ"),
        "u": Array("úùủũụ"), "ư": Array("ứừửữự"), "y": Array("ýỳỷỹỵ"),
    ]
    private static let toneKeys: [Character: Int] = ["s": 1, "f": 2, "r": 3, "x": 4, "j": 5]
    private static let initials: Set<String> = Set(
        "b c ch d đ g gh gi h k kh l m n ng ngh nh p ph qu r s t th tr v x"
            .split(separator: " ").map(String.init)).union([""])
    private static let finals: Set<String> = ["", "c", "ch", "m", "n", "ng", "nh", "p", "t"]
    private static let nuclei: Set<String> = Set("""
        a ă â e ê i o ô ơ u ư y
        ai ao au ay âu ây eo êu ia iê iu oa oă oe oi ôi ơi oo ua uâ ue uê ui uô uơ uy ưa ưi ưu ươ yê
        iêu oai oao oay oeo uây uôi uya uyê uyu ươi ươu yêu
        """.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init))

    // MARK: - Trạng thái

    /// true = kiểu cũ (òa, khỏe, thúy); false = kiểu mới (oà, khoẻ, thuý)
    var oldStyle: Bool
    private(set) var letters: [Letter] = []
    private(set) var tone = 0
    /// Các phím đã gõ; nil khi không còn khôi phục được (sau backspace / hoàn tác).
    private(set) var raw: String? = ""

    init(oldStyle: Bool = true) { self.oldStyle = oldStyle }

    var isComposing: Bool { !letters.isEmpty }

    func reset() {
        letters = []
        tone = 0
        raw = ""
    }

    // MARK: - Cấu trúc âm tiết

    /// Cụm nguyên âm cuối cùng: start..<end
    private func vowelRun() -> Range<Int>? {
        guard let last = letters.lastIndex(where: { Self.vowels.contains($0.base) }) else { return nil }
        var start = last
        while start > 0 && Self.vowels.contains(letters[start - 1].base) { start -= 1 }
        return start..<(last + 1)
    }

    /// Nguyên âm chính (bỏ "u" của "qu", "i" của "gi") và có phụ âm cuối hay không.
    private func nucleus() -> (idx: [Int], hasFinal: Bool) {
        guard let run = vowelRun() else { return ([], false) }
        var idx = Array(run)
        if idx.count > 1 && run.lowerBound > 0 {
            let prev = letters[run.lowerBound - 1], first = letters[run.lowerBound]
            if prev.base == "q" && first.base == "u" && first.mod == .none {
                idx.removeFirst()
            } else if prev.base == "g" && first.base == "i" {
                idx.removeFirst()
            }
        }
        return (idx, run.upperBound < letters.count)
    }

    private func toneIndex() -> Int? {
        let (idx, hasFinal) = nucleus()
        guard !idx.isEmpty else { return nil }
        let modified = idx.filter { [Mod.hat, .breve, .horn].contains(letters[$0].mod) }
        if let m = modified.last { return m }
        if idx.count == 1 { return idx[0] }
        if idx.count == 2 {
            if hasFinal { return idx[1] }
            let pair = String([letters[idx[0]].base, letters[idx[1]].base])
            if !oldStyle && ["oa", "oe", "uy"].contains(pair) { return idx[1] }
            return idx[0]
        }
        return idx[1]
    }

    // MARK: - Hiển thị

    func render() -> String {
        let ti = tone > 0 ? toneIndex() : nil
        var out = ""
        for (i, l) in letters.enumerated() {
            var c = l.plain
            if i == ti, let forms = Self.toned[c] { c = forms[tone - 1] }
            out += l.upper ? String(c).uppercased() : String(c)
        }
        return out
    }

    func isValidSyllable() -> Bool {
        let s = Array(String(letters.map { $0.plain }))
        var i = 0
        while i < s.count && !Self.vnVowels.contains(s[i]) { i += 1 }
        var j = i
        while j < s.count && Self.vnVowels.contains(s[j]) { j += 1 }
        var c1 = String(s[..<i]), v = String(s[i..<j])
        let c2 = String(s[j...])
        if c2.contains(where: { Self.vnVowels.contains($0) }) { return false }
        if c1 == "q" && v.hasPrefix("u") && v.count > 1 {
            c1 = "qu"; v.removeFirst()
        } else if c1 == "g" && v.hasPrefix("i") && v.count > 1 {
            c1 = "gi"; v.removeFirst()
        }
        guard Self.initials.contains(c1), Self.finals.contains(c2), Self.nuclei.contains(v) else { return false }
        if ["c", "ch", "p", "t"].contains(c2) && tone != 1 && tone != 5 { return false }
        return true
    }

    // MARK: - Xử lý phím

    private func append(_ ch: Character, mod: Mod = .none, fromW: Bool = false) {
        letters.append(Letter(base: Character(ch.lowercased()), upper: ch.isUppercase, mod: mod, fromW: fromW))
    }

    private func undo(_ ch: Character) {
        append(ch)
        raw = nil  // người dùng chủ động hoàn tác -> không tự khôi phục nữa
    }

    /// Nhận một chữ cái ASCII (a–z, A–Z).
    func key(_ ch: Character) {
        let k = Character(ch.lowercased())
        raw?.append(ch)
        let (idx, _) = nucleus()
        let hasVowel = letters.contains { Self.vowels.contains($0.base) }

        if Self.toneKeys[k] != nil || k == "z" {
            guard hasVowel else { return append(ch) }
            if k == "z" {
                if tone != 0 { tone = 0 } else { append(ch) }
                return
            }
            let t = Self.toneKeys[k]!
            if tone == t {
                tone = 0
                return undo(ch)
            }
            tone = t
            return
        }

        if k == "a" || k == "e" || k == "o" {
            if let run = vowelRun() {
                for i in run.reversed() where letters[i].base == k {
                    if letters[i].mod == .hat {
                        letters[i].mod = .none
                        return undo(ch)
                    }
                    letters[i].mod = .hat
                    return
                }
            }
            return append(ch)
        }

        if k == "w" {
            if let last = letters.last, last.fromW, last.mod == .horn {
                letters.removeLast()
                return undo(ch)
            }
            if idx.isEmpty {
                return append(ch.isUppercase ? "U" : "u", mod: .horn, fromW: true)
            }
            for (a, b) in zip(idx, idx.dropFirst()) where letters[a].base == "u" && letters[b].base == "o" {
                if letters[a].mod == .horn && letters[b].mod == .horn {
                    letters[a].mod = .none
                    letters[b].mod = .none
                    return undo(ch)
                }
                letters[a].mod = .horn
                letters[b].mod = .horn
                return
            }
            let bases = String(idx.map { letters[$0].base })
            var target: (Int, Mod)?
            if bases.contains("oa"), let i = idx.first(where: { letters[$0].base == "a" }) {
                target = (i, .breve)
            } else {
                for (base, mod) in [("o", Mod.horn), ("u", .horn), ("a", .breve)] as [(Character, Mod)] {
                    if let i = idx.last(where: { letters[$0].base == base }) {
                        target = (i, mod)
                        break
                    }
                }
            }
            guard let found = target else { return append(ch) }
            let (i, mod) = found
            if letters[i].mod == mod {
                letters[i].mod = .none
                return undo(ch)
            }
            letters[i].mod = mod
            return
        }

        if k == "d", let first = letters.first, first.base == "d" {
            if first.mod == .none {
                letters[0].mod = .stroke
                return
            }
            if first.mod == .stroke {
                letters[0].mod = .none
                return undo(ch)
            }
        }

        append(ch)
    }

    /// Xóa chữ cuối. Trả về false nếu không có gì để xóa.
    @discardableResult
    func backspace() -> Bool {
        guard !letters.isEmpty else { return false }
        letters.removeLast()
        raw = nil
        if !letters.contains(where: { Self.vowels.contains($0.base) }) { tone = 0 }
        return true
    }

    /// Kết thúc từ hiện tại, trả về chuỗi cần chèn.
    func commit(autoRestore: Bool = true) -> String {
        guard !letters.isEmpty else { return "" }
        var out = render()
        if autoRestore, let raw = raw, !isValidSyllable() { out = raw }
        reset()
        return out
    }

    /// Kết thúc từ, trả về đúng các phím đã gõ (dùng cho phím Esc).
    func commitRaw() -> String {
        let out = raw ?? render()
        reset()
        return out
    }
}
