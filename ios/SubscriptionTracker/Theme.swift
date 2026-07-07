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

/// Cumulative spend curve for the whole month in the design's plot units:
/// x in day-space, y within the 137pt-tall plot (lower y = higher spend).
/// Days 17.3-23 keep the exact vertex geometry of the Figma curve, so the
/// default window (18-23) renders identical to the design.
let curveVertices: [(day: CGFloat, y: CGFloat)] = [
    (1, 132), (2, 127), (3, 128.5), (4, 121), (5, 116), (6, 117.5),
    (7, 110), (8, 112), (9, 104), (10, 106), (11, 99), (12, 101),
    (13, 95), (14, 97), (15, 108), (16, 122), (17, 134),
    (17.325, 136.546), (17.494, 136.546), (18.008, 116.975), (18.417, 116.975),
    (19.008, 61.72), (20.008, 55.7515), (23.008, 0.478),
    (24, -6), (25, -20), (26, -45), (27, -49), (28, -63), (29, -67), (30, -77), (31, -83),
]

func rawY(atDay d: CGFloat) -> CGFloat {
    guard let first = curveVertices.first, let last = curveVertices.last else { return 0 }
    if d <= first.day { return first.y }
    for i in 1..<curveVertices.count {
        let a = curveVertices[i - 1], b = curveVertices[i]
        if d <= b.day {
            return a.y + (d - a.day) / (b.day - a.day) * (b.y - a.y)
        }
    }
    return last.y
}

/// Vertical normalization of the visible window: the default window (18-23)
/// maps 1:1 to the design; other windows fill the plot sensibly.
struct NormBounds {
    let hi: CGFloat
    let span: CGFloat
}

func normBounds(offset o: CGFloat) -> NormBounds {
    var lo = CGFloat.greatestFiniteMagnitude
    var hi = -CGFloat.greatestFiniteMagnitude
    var d = o - 0.6833
    while d <= o + 5.0167 {
        let y = rawY(atDay: d)
        lo = min(lo, y)
        hi = max(hi, y)
        d += 0.05
    }
    return NormBounds(hi: hi, span: max(hi - lo, 20))
}

func normY(_ y: CGFloat, _ b: NormBounds) -> CGFloat {
    136.546 - (b.hi - y) * (136.068 / b.span)
}

/// x position of day d when the chart window starts at (fractional) offset o
func windowX(day d: CGFloat, offset o: CGFloat) -> CGFloat {
    (d - o) * 60 + 41
}

struct DayDelta {
    let amount: String
    let percent: String
}

/// Daily spend deltas for every day; 18-23 keep the design's values
let dayDeltas: [Int: DayDelta] = [
    1: DayDelta(amount: "+$2.99", percent: "(+2%)"),
    2: DayDelta(amount: "+$1.49", percent: "(+1%)"),
    3: DayDelta(amount: "+$4.99", percent: "(+3%)"),
    4: DayDelta(amount: "+$0.99", percent: "(+1%)"),
    5: DayDelta(amount: "+$7.99", percent: "(+4%)"),
    6: DayDelta(amount: "+$2.49", percent: "(+1%)"),
    7: DayDelta(amount: "+$5.99", percent: "(+3%)"),
    8: DayDelta(amount: "+$1.99", percent: "(+1%)"),
    9: DayDelta(amount: "+$9.99", percent: "(+5%)"),
    10: DayDelta(amount: "+$3.49", percent: "(+2%)"),
    11: DayDelta(amount: "+$6.99", percent: "(+3%)"),
    12: DayDelta(amount: "+$2.99", percent: "(+1%)"),
    13: DayDelta(amount: "+$8.49", percent: "(+4%)"),
    14: DayDelta(amount: "+$4.49", percent: "(+2%)"),
    15: DayDelta(amount: "+$10.99", percent: "(+5%)"),
    16: DayDelta(amount: "+$3.99", percent: "(+2%)"),
    17: DayDelta(amount: "+$5.49", percent: "(+2%)"),
    18: DayDelta(amount: "+$4.20", percent: "(+2%)"),
    19: DayDelta(amount: "+$18.50", percent: "(+8%)"),
    20: DayDelta(amount: "+$2.99", percent: "(+1%)"),
    21: DayDelta(amount: "+$11.99", percent: "(+5%)"),
    22: DayDelta(amount: "+$8.00", percent: "(+3%)"),
    23: DayDelta(amount: "+$25.00", percent: "(+1%)"),
    24: DayDelta(amount: "+$2.99", percent: "(+1%)"),
    25: DayDelta(amount: "+$8.00", percent: "(+3%)"),
    26: DayDelta(amount: "+$25.00", percent: "(+9%)"),
    27: DayDelta(amount: "+$1.99", percent: "(+1%)"),
    28: DayDelta(amount: "+$11.99", percent: "(+4%)"),
    29: DayDelta(amount: "+$3.49", percent: "(+1%)"),
    30: DayDelta(amount: "+$8.00", percent: "(+3%)"),
    31: DayDelta(amount: "+$5.99", percent: "(+2%)"),
]

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
