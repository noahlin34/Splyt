import SwiftUI
import UIKit

extension Color {
    init?(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") { sanitized = String(sanitized.dropFirst()) }
        guard sanitized.count == 6, let value = UInt64(sanitized, radix: 16) else { return nil }
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

extension Color {
    static let personPresets: [String] = [
        "FF6B6B", "4ECDC4", "45B7D1", "96CEB4",
        "FFEAA7", "DDA0DD", "98D8C8", "F7DC6F"
    ]

    static let splytGreen      = Color(hex: "2bee7c") ?? .green
    static let splytDark       = Color(hex: "0f172a") ?? Color(.label)
    static let splytSecondary  = Color(hex: "64748b") ?? Color(.secondaryLabel)
    static let splytMuted      = Color(hex: "94a3b8") ?? Color(.tertiaryLabel)
    static let splytBackground = Color(hex: "f6f8f7") ?? Color(.systemGroupedBackground)
    static let splytBorder     = Color(hex: "f1f5f9") ?? Color(.systemGray6)
    static let splytRed        = Color(hex: "ef4444") ?? .red
}
