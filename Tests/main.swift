// Chạy test engine: swiftc Sources/TelexEngine.swift Tests/main.swift -o build/tests && build/tests Tests/cases.tsv
import Foundation

func typeText(_ text: String, oldStyle: Bool) -> String {
    let e = TelexEngine(oldStyle: oldStyle)
    var out = ""
    for ch in text {
        if ch.isASCII && ch.isLetter {
            e.key(ch)
        } else {
            out += e.commit() + String(ch)
        }
    }
    return out + e.commit()
}

let path = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Tests/cases.tsv"
guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
    print("Không đọc được \(path)")
    exit(2)
}

var total = 0, fails = 0
for line in content.split(separator: "\n") where !line.hasPrefix("#") && !line.isEmpty {
    let cols = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
    guard cols.count == 3 else { continue }
    total += 1
    let got = typeText(cols[1], oldStyle: cols[0] == "old")
    if got != cols[2] {
        fails += 1
        print("FAIL [\(cols[0])] \"\(cols[1])\": được \"\(got)\", cần \"\(cols[2])\"")
    }
}
print("\(total - fails)/\(total) test đạt")
exit(fails == 0 ? 0 : 1)
