import SwiftUI

/// The design is a fixed 393pt-wide canvas (iPhone 15 Pro logical width).
/// The native status bar and home indicator replace the mocked ones from
/// the design; everything between is scaled uniformly to fit the device.
struct HomeView: View {
    /// Design canvas height: 852 minus the mocked status bar (59)
    /// and home indicator area (34)
    private let canvasSize = CGSize(width: 393, height: 759)

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / canvasSize.width, geo.size.height / canvasSize.height)
            canvas
                .frame(width: canvasSize.width, height: canvasSize.height)
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(alignment: .bottom) {
            // the tab bar's white extends into the bottom safe area
            Color.white.frame(height: 120).ignoresSafeArea(edges: .bottom)
        }
        .background(Palette.background.ignoresSafeArea())
    }

    private var canvas: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                TopBar()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        SpendGraphView()
                            .frame(width: 393, height: 301)
                        SubscriptionListView()
                        // room so the list can scroll clear of the tab bar
                        Color.clear.frame(height: 76)
                    }
                }
            }

            TabBar()

            fab
                .padding(.trailing, 20)
                .padding(.bottom, 76)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .background(Palette.background)
    }

    private var fab: some View {
        Button {
        } label: {
            Image("plus")
                .resizable()
                .frame(width: 24, height: 24)
                .padding(20)
                .background(Circle().fill(Palette.ink))
                .shadow(color: .black.opacity(0.05), radius: 3.25, x: 0, y: 5)
                .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 2)
        }
    }
}

struct TopBar: View {
    var body: some View {
        ZStack {
            Text("Tue, June 23")
                .font(AppFont.geistMedium(14))
                .tracking(0.24)
                .foregroundStyle(Palette.ink)
                .offset(x: 0.5)

            HStack {
                Image("avatar")
                    .resizable()
                    .frame(width: 32, height: 32)
                Spacer()
                Image("bell")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 20)
        }
        .frame(width: 393, height: 52)
    }
}

struct TabBar: View {
    var body: some View {
        HStack {
            tab("tab-house")
            Spacer()
            tab("tab-calendar")
            Spacer()
            tab("tab-chart")
            Spacer()
            tab("tab-gear")
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 8)
        .frame(width: 393, height: 56)
        .background(Color.white)
        .overlay(alignment: .topLeading) {
            // active-tab indicator
            UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
                .fill(LinearGradient(colors: [Palette.wine, Palette.flame], startPoint: .top, endPoint: .bottom))
                .frame(width: 24, height: 4)
                .offset(x: 48)
        }
    }

    private func tab(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .padding(8)
    }
}

#Preview {
    HomeView()
}
