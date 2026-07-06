import SwiftUI

/// The design is a fixed 393x852 canvas (iPhone 15 Pro logical size),
/// including the mocked status bar and home indicator from the Figma frame.
/// The real system chrome is hidden and the canvas scales to fit the device.
struct HomeView: View {
    private let canvasSize = CGSize(width: 393, height: 852)

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / canvasSize.width, geo.size.height / canvasSize.height)
            canvas
                .frame(width: canvasSize.width, height: canvasSize.height)
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Palette.background.ignoresSafeArea())
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var canvas: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                StatusBarView()
                TopBar()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        SpendGraphView()
                            .frame(width: 393, height: 301)
                        SubscriptionListView()
                        // room so the list can scroll clear of the tab bar
                        Color.clear.frame(height: 110)
                    }
                }
            }

            VStack(spacing: 0) {
                TabBar()
                HomeIndicatorView()
            }

            fab
                .padding(.trailing, 20)
                .padding(.bottom, 110)
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
