import SwiftUI

/// The fixed graph block (393x301): spend summary, curve, scrubbable
/// annotation, and the horizontally scrollable date rail at the bottom.
struct SpendGraphView: View {
    @State private var selectedDay = 23
    @State private var tooltipVisible = false
    @State private var dotDragMoved = false

    /// vertical offset of the plot area inside the graph block
    private let plotTop: CGFloat = 132
    private let tooltipSize = CGSize(width: 110, height: 56)
    /// y where the date rail begins; the tooltip must stay above it
    private let railTop: CGFloat = 269

    private var onChart: Bool { dayDeltas[selectedDay] != nil }

    private var markerX: CGFloat { dayX(selectedDay) }

    private var dotCenter: CGPoint {
        // day 23 pins to the exact dot position from the design
        let y = selectedDay == 23 ? 132 : plotTop + curveY(at: markerX)
        return CGPoint(x: markerX, y: y)
    }

    private var tooltipOrigin: CGPoint {
        let below = dotCenter.y - 10 + 28
        let top = below + tooltipSize.height > railTop ? dotCenter.y - 10 - 8 - tooltipSize.height : below
        let left = min(263, max(10, markerX - 78))
        return CGPoint(x: left, y: top)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            spendSummary
                .padding(.horizontal, 20)
                .padding(.top, 20)

            curveArea
                .frame(width: 393, height: 137)
                .offset(y: plotTop)

            // scrub anywhere across the plot — kept BENEATH the dot so the
            // dot's own tap/drag gesture wins when touching it directly
            Color.clear
                .contentShape(Rectangle())
                .frame(width: 393, height: 153)
                .offset(y: 116)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("graph"))
                        .onChanged { value in pickDay(at: value.location.x) }
                )

            dashedMarker
            graphDot
            tooltip

            DateRail(selectedDay: $selectedDay, onSelect: select(day:))
                .offset(y: railTop)
        }
        .frame(width: 393, height: 301, alignment: .topLeading)
        .coordinateSpace(name: "graph")
    }

    // MARK: - Pieces

    private var spendSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total spend this month")
                .font(AppFont.geistMedium(12))
                .foregroundStyle(Palette.label)
            Text("$247.94")
                .font(AppFont.geistMedium(32))
                .tracking(-0.16)
                .foregroundStyle(Palette.ink)
            HStack(spacing: 4) {
                Image("caret-up")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 10, height: 10)
                Text("+$12 (7%)")
                    .font(AppFont.geistMedium(12))
                    .foregroundStyle(Palette.green)
                Text("vs last month")
                    .font(AppFont.geistMedium(12))
                    .foregroundStyle(Palette.label)
            }
        }
    }

    private var curveArea: some View {
        ZStack(alignment: .topLeading) {
            // gradient fill under the curve (from the design's SVG)
            areaPath
                .fill(LinearGradient(
                    stops: [
                        .init(color: Palette.areaTint, location: 33.78 / 137),
                        .init(color: Palette.areaTint.opacity(0), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            // the spend curve itself
            linePath
                .stroke(Palette.wine, lineWidth: 1)
        }
    }

    private var areaPath: Path {
        Path { p in
            p.move(to: CGPoint(x: 10.1845, y: 136.068))
            p.addLine(to: CGPoint(x: 0, y: 136.068))
            p.addLine(to: CGPoint(x: 0, y: 137))
            p.addLine(to: CGPoint(x: 393, y: 137))
            p.addLine(to: CGPoint(x: 393, y: 0))
            p.addLine(to: CGPoint(x: 341, y: 0))
            p.addLine(to: CGPoint(x: 161, y: 55.2735))
            p.addLine(to: CGPoint(x: 101, y: 61.2421))
            p.addLine(to: CGPoint(x: 65.5, y: 116.497))
            p.addLine(to: CGPoint(x: 41, y: 116.497))
            p.closeSubpath()
        }
    }

    private var linePath: Path {
        Path { p in
            p.move(to: CGPoint(x: 0.5, y: 137.478))
            p.addLine(to: CGPoint(x: 0.5, y: 136.546))
            for point in spendCurve.dropFirst() {
                p.addLine(to: point)
            }
        }
    }

    private var dashedMarker: some View {
        Path { p in
            p.move(to: CGPoint(x: 0.5, y: 0))
            p.addLine(to: CGPoint(x: 0.5, y: 153))
        }
        .stroke(Palette.ink.opacity(0.1), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [4, 4]))
        .frame(width: 1, height: 153)
        .offset(x: markerX - 0.5, y: plotTop)
        .opacity(onChart ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: markerX)
        .animation(.easeInOut(duration: 0.25), value: onChart)
        .allowsHitTesting(false)
    }

    private var graphDot: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.05), radius: 3.25, x: 0, y: 5)
                .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 2)
            Circle()
                .fill(LinearGradient(colors: [Palette.wine, Palette.flame], startPoint: .top, endPoint: .bottom))
                .frame(width: 8, height: 8)
        }
        .frame(width: 20, height: 20)
        // generous 40pt touch target; hit shape scoped to the dot itself,
        // and drag locations read in the graph's coordinate space
        .contentShape(Circle().inset(by: -10))
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("graph"))
                .onChanged { value in
                    if abs(value.translation.width) > 3 { dotDragMoved = true }
                    if dotDragMoved { pickDay(at: value.location.x) }
                }
                .onEnded { _ in
                    if !dotDragMoved {
                        withAnimation(.easeInOut(duration: 0.25)) { tooltipVisible.toggle() }
                    }
                    dotDragMoved = false
                }
        )
        .position(dotCenter)
        .opacity(onChart ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: dotCenter)
        .animation(.easeInOut(duration: 0.25), value: onChart)
    }

    private var tooltip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(selectedDay) Jun 2026")
                .font(AppFont.geistMedium(12))
                .foregroundStyle(Palette.label)
            HStack(spacing: 8) {
                Text(dayDeltas[selectedDay]?.amount ?? "")
                    .font(AppFont.geistMedium(12))
                    .foregroundStyle(Palette.ink)
                Text(dayDeltas[selectedDay]?.percent ?? "")
                    .font(AppFont.geistMedium(12))
                    .foregroundStyle(Palette.green)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(width: tooltipSize.width, height: tooltipSize.height, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 3.25, x: 0, y: 5)
                .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 2)
        )
        .offset(x: tooltipOrigin.x, y: tooltipOrigin.y)
        .opacity(tooltipVisible && onChart ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: tooltipVisible)
        .animation(tooltipVisible ? .easeInOut(duration: 0.25) : nil, value: tooltipOrigin)
        .allowsHitTesting(false)
    }

    // MARK: - Interaction

    private func pickDay(at x: CGFloat) {
        let nearest = chartedDays.min(by: { abs(dayX($0) - x) < abs(dayX($1) - x) }) ?? 23
        select(day: nearest)
    }

    private func select(day: Int) {
        guard day != selectedDay else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedDay = day
            if dayDeltas[day] == nil { tooltipVisible = false }
        }
    }
}

/// Horizontally scrollable date rail; the graph above stays fixed.
struct DateRail: View {
    @Binding var selectedDay: Int
    var onSelect: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 32) {
                    ForEach(1...31, id: \.self) { day in
                        cell(day)
                            .id(day)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .frame(width: 393)
            .onAppear {
                // start with days 18-23 placed exactly as in the design
                // (day 23's cell center lands at x = 341)
                proxy.scrollTo(23, anchor: UnitPoint(x: 0.8959, y: 0.5))
            }
        }
    }

    private func cell(_ day: Int) -> some View {
        Button {
            onSelect(day)
        } label: {
            Text("\(day)")
                .font(AppFont.geistMedium(12))
                .foregroundStyle(day == selectedDay ? .white : Palette.label)
                .frame(width: 28, height: 16)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Palette.ink)
                        .opacity(day == selectedDay ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: selectedDay)
    }
}
