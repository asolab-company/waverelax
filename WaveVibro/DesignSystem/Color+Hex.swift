import SwiftUI

extension Color {
    init(hex: String) {
        let token = hex
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let components = Self.parseHexComponents(from: token) ?? (0, 0, 0, 1)
        self.init(
            .sRGB,
            red: components.red,
            green: components.green,
            blue: components.blue,
            opacity: components.opacity
        )
    }

    private static func parseHexComponents(from token: String) -> (red: Double, green: Double, blue: Double, opacity: Double)? {
        guard let rawValue = UInt64(token, radix: 16) else { return nil }

        switch token.count {
        case 3:
            let red = Double((rawValue >> 8) & 0xF) / 15
            let green = Double((rawValue >> 4) & 0xF) / 15
            let blue = Double(rawValue & 0xF) / 15
            return (red, green, blue, 1)
        case 6:
            let red = Double((rawValue >> 16) & 0xFF) / 255
            let green = Double((rawValue >> 8) & 0xFF) / 255
            let blue = Double(rawValue & 0xFF) / 255
            return (red, green, blue, 1)
        case 8:
            let red = Double((rawValue >> 24) & 0xFF) / 255
            let green = Double((rawValue >> 16) & 0xFF) / 255
            let blue = Double((rawValue >> 8) & 0xFF) / 255
            let opacity = Double(rawValue & 0xFF) / 255
            return (red, green, blue, opacity)
        default:
            return nil
        }
    }
}
