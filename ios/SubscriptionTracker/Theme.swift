import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

/// Colors lifted 1:1 from the Figma design
enum Palette {
    static let background = Color(hex: 0xF7F7F7)
    static let ink = Color(hex: 0x111111)
    static let label = Color(hex: 0x4F4F4F)
    static let sectionLabel = Color(hex: 0x535353)
    static let secondary = Color(hex: 0x767676)
    static let separator = Color(hex: 0xE9E9E9)
    static let iconCircle = Color(hex: 0xF2F2F2)
    static let pill = Color(hex: 0xF5F5F5)
    static let green = Color(hex: 0x2B8764)
    static let wine = Color(hex: 0xA42661)
    static let flame = Color(hex: 0xDE3341)
    static let cancelRed = Color(hex: 0xE50914)
    static let areaTint = Color(hex: 0xF8E4ED)
}

enum AppFont {
    static func geistMedium(_ size: CGFloat) -> Font { .custom("Geist-Medium", size: size) }
    static func geistSemiBold(_ size: CGFloat) -> Font { .custom("Geist-SemiBold", size: size) }
    static func interMedium(_ size: CGFloat) -> Font { .custom("Inter-Medium", size: size) }
}

// MARK: - Graph data

/// Spend curve polyline from the design's SVG path,
/// x across the 393pt width, y within the 137pt-tall plot (origin at plot top)
let spendCurve: [CGPoint] = [
    CGPoint(x: 0.5, y: 136.546),
    CGPoint(x: 10.6845, y: 136.546),
    CGPoint(x: 41.5, y: 116.975),
    CGPoint(x: 66, y: 116.975),
    CGPoint(x: 101.5, y: 61.72),
    CGPoint(x: 161.5, y: 55.7515),
    CGPoint(x: 341.5, y: 0.478),
]

func curveY(at x: CGFloat) -> CGFloat {
    guard let first = spendCurve.first, let last = spendCurve.last else { return 0 }
    if x <= first.x { return first.y }
    for i in 1..<spendCurve.count {
        let p0 = spendCurve[i - 1], p1 = spendCurve[i]
        if x <= p1.x {
            return p0.y + (x - p0.x) / (p1.x - p0.x) * (p1.y - p0.y)
        }
    }
    return last.y
}

struct DayDelta {
    let amount: String
    let percent: String
}

/// Daily spend deltas for the charted window; day 23 keeps the design's values
let dayDeltas: [Int: DayDelta] = [
    18: DayDelta(amount: "+$4.20", percent: "(+2%)"),
    19: DayDelta(amount: "+$18.50", percent: "(+8%)"),
    20: DayDelta(amount: "+$2.99", percent: "(+1%)"),
    21: DayDelta(amount: "+$11.99", percent: "(+5%)"),
    22: DayDelta(amount: "+$8.00", percent: "(+3%)"),
    23: DayDelta(amount: "+$25.00", percent: "(+1%)"),
]

let chartedDays = [18, 19, 20, 21, 22, 23]

/// A day's marker position across the fixed graph, matching the design:
/// the date rail cell for day d is centered at (d-1)*60 - 979
func dayX(_ day: Int) -> CGFloat {
    CGFloat(day - 1) * 60 - 979
}

// MARK: - Subscriptions

struct Subscription: Identifiable {
    let id = UUID()
    let icon: String
    let iconSize: CGSize
    let name: String
    let renews: String
    let price: String
}

let subscriptions: [Subscription] = [
    Subscription(icon: "icloud", iconSize: CGSize(width: 24, height: 15), name: "iCloud+", renews: "Renews 24 June", price: "$2.99"),
    Subscription(icon: "nyt", iconSize: CGSize(width: 24, height: 24), name: "The New York Times", renews: "Renews 26 June", price: "$25.00"),
    Subscription(icon: "spotify", iconSize: CGSize(width: 24, height: 24), name: "Spotify", renews: "Renews 28 June", price: "$11.99"),
    Subscription(icon: "netflix", iconSize: CGSize(width: 24, height: 24), name: "Netflix", renews: "Renews 25 June", price: "$8.00"),
    Subscription(icon: "notion", iconSize: CGSize(width: 23, height: 24), name: "Notion", renews: "Renews 30 June", price: "$8.00"),
]
