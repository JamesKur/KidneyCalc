import SwiftUI

/// Parses a formula string containing subscript notation (e.g., "Na_infusate")
/// and returns a styled SwiftUI Text with proper subscript formatting.
///
/// Usage:
///   formulaText("EFWC = V × [1 − (U_Na + U_K) / S_Na]")
///
/// Subscript rules:
///   - An underscore followed by alphanumeric characters is rendered as a subscript
///   - The subscript continues until a non-alphanumeric character is encountered
func formulaText(
    _ string: String,
    baseFont: Font = .system(.body, design: .monospaced),
    subscriptSize: CGFloat = 12,
    subscriptOffset: CGFloat = -4
) -> Text {
    var attributed = AttributedString()
    var normalBuffer = ""
    var i = string.startIndex

    func flushNormal() {
        guard !normalBuffer.isEmpty else { return }
        var part = AttributedString(normalBuffer)
        part.font = baseFont
        attributed.append(part)
        normalBuffer = ""
    }

    while i < string.endIndex {
        if string[i] == "_" {
            let afterUnderscore = string.index(after: i)
            guard afterUnderscore < string.endIndex else {
                normalBuffer.append("_")
                i = afterUnderscore
                continue
            }
            // Collect subscript characters (letters and digits)
            var j = afterUnderscore
            while j < string.endIndex, string[j].isLetter || string[j].isNumber {
                j = string.index(after: j)
            }
            if j == afterUnderscore {
                // Underscore not followed by alphanumeric — treat as literal
                normalBuffer.append("_")
                i = afterUnderscore
            } else {
                flushNormal()
                var sub = AttributedString(String(string[afterUnderscore..<j]))
                sub.font = .system(size: subscriptSize, design: .monospaced)
                sub.baselineOffset = subscriptOffset
                attributed.append(sub)
                i = j
            }
        } else {
            normalBuffer.append(string[i])
            i = string.index(after: i)
        }
    }

    flushNormal()
    return Text(attributed)
}

/// Overload for caption-sized formula text
func formulaCaptionText(_ string: String) -> Text {
    formulaText(
        string,
        baseFont: .system(.caption, design: .monospaced),
        subscriptSize: 8,
        subscriptOffset: -3
    )
}
