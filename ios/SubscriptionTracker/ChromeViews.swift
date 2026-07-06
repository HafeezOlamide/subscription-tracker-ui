import SwiftUI

/// The design's mocked iOS status bar (393x59): "9:41" on the left,
/// signal/wifi/battery on the right, dynamic-island gap in the middle.
struct StatusBarView: View {
    var body: some View {
        HStack(spacing: 0) {
            // left side: time, centered in the flexible column
            Text("9:41")
                .font(.system(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(.black)
                .frame(width: 54, height: 21)
                .frame(maxWidth: .infinity)
                .padding(.leading, 10)
                .padding(.bottom, 3)

            // dynamic island gap
            Color.clear
                .frame(width: 125)

            // right side: signal, wifi, battery
            Image("statusbar-signal")
                .resizable()
                .frame(width: 78.401, height: 13)
                .frame(maxWidth: .infinity)
                .padding(.trailing, 11)
        }
        .frame(width: 393, height: 59)
    }
}

/// The design's mocked home indicator area (393x34):
/// a 134x5 black pill, 8pt above the bottom edge, on white.
struct HomeIndicatorView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white
            Capsule()
                .fill(Color.black)
                .frame(width: 134, height: 5)
                .padding(.bottom, 8)
        }
        .frame(width: 393, height: 34)
    }
}

#Preview("Status Bar") {
    StatusBarView()
        .background(Palette.background)
}

#Preview("Home Indicator") {
    HomeIndicatorView()
}
