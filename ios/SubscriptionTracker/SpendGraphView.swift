import SwiftUI

/// The spend curve for the current 6-day window; `offset` is the fractional
/// window start so window changes pan smoothly.
struct CurveLineShape: Shape {
    var offset: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let b = normBounds(offset: offset)
        var p = Path()
        var first = true
        for (d, y) in samples(from: offset - 0.6833, to: offset + 5.0167) {
            let pt = CGPoint(x: windowX(day: d, offset: offset), y: normY(y, b))
            if first { p.move(to: pt); first = false } else { p.addLine(to: pt) }
        }
        return p
    }
}

/// The gradient fill under the curve; extends to the plot's right edge
/// like the design's area shape.
struct CurveAreaShape: Shape {
    var offset: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let b = normBounds(offset: offset)
        var p = Path()
        var first = true
        for (d, y) in samples(from: offset - 0.6833, to: offset + 5.8667) {
            let pt = CGPoint(x: windowX(day: d, offset: offset), y: normY(y, b))
            if first { p.move(to: pt); first = false } else { p.addLine(to: pt) }
        }
        p.addLine(to: CGPoint(x: 393, y: 137))
        p.addLine(to: CGPoint(x: 0, y: 137))
        p.closeSubpath()
        return p
    }
}

/// Curve vertices within [from, to] plus interpolated endpoints
func samples(from: CGFloat, to: CGFloat) -> [(CGFloat, CGFloat)] {
    var pts: [(CGFloat, CGFloat)] = [(from, rawY(atDay: from))]
    for (vd, vy) in curveVertices where vd > from && vd < to {
        pts.append((vd, vy))
    }
    pts.append((to, rawY(atDay: to)))
    return pts
}

/// The fixed graph block (393x301): spend summary, sliding curve window,
/// date-anchored annotation, and the scrollable date rail at the bottom.
struct SpendGraphView: View {
    @State private var selectedDay = 23
    @State private var windowStart = 18
    @State private var tooltipVisible = false
    @State private var dotDragMoved = false

    private let plotTop: CGFloat = 132
    private let tooltipSize = CGSize(width: 110, height: 56)
    /// y where the date rail begins; the tooltip must stay above it
    private let railTop: CGFloat = 269
    private let windowLast = 26

    private var markerX: CGFloat {
        windowX(day: CGFloat(selectedDay), offset: CGFloat(windowStart))
    }

    private var dotCenter: CGPoint {
        let b = normBounds(offset: CGFloat(windowStart))
        // day vertices sit at d+0.008 (the design's half-pixel offset)
        let y = normY(rawY(atDay: min(CGFloat(selectedDay) + 0.008, 31)), b)
        return CGPoint(x: markerX, y: plotTop + y)
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

            DateRail(selectedDay: $selectedDay, windowStart: $windowStart, onSelect: select(day:))
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
            CurveAreaShape(offset: CGFloat(windowStart))
                .fill(LinearGradient(
                    stops: [
                        .init(color: Palette.areaTint, location: 33.78 / 137),
                        .init(color: Palette.areaTint.opacity(0), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            CurveLineShape(offset: CGFloat(windowStart))
                .stroke(Palette.wine, lineWidth: 1)
        }
        .clipped()
        .animation(.easeInOut(duration: 0.25), value: windowStart)
    }

    private var dashedMarker: some View {
        Path { p in
            p.move(to: CGPoint(x: 0.5, y: 0))
            p.addLine(to: CGPoint(x: 0.5, y: 153))
        }
        .stroke(Palette.ink.opacity(0.1), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [4, 4]))
        .frame(width: 1, height: 153)
        .offset(x: markerX - 0.5, y: plotTop)
        .animation(.easeInOut(duration: 0.25), value: markerX)
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
        .animation(.easeInOut(duration: 0.25), value: dotCenter)
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
        .opacity(tooltipVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: tooltipVisible)
        .animation(tooltipVisible ? .easeInOut(duration: 0.25) : nil, value: tooltipOrigin)
        .allowsHitTesting(false)
    }

    // MARK: - Interaction

    private func pickDay(at x: CGFloat) {
        let k = min(max(Int((x - 41) / 60 + 0.5), 0), 5)
        select(day: windowStart + k)
    }

    private func select(day: Int) {
        guard day != selectedDay, (1...31).contains(day) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedDay = day
            // slide the window so the selected date sits at its right edge,
            // matching the design's default (day 23 at the end of the chart)
            if day < windowStart || day > windowStart + 5 {
                windowStart = min(max(day - 5, 1), windowLast)
            }
        }
    }
}

/// Horizontally scrollable date rail; tapping any date selects it and the
/// chart window slides so the marker lands on that date.
struct DateRail: View {
    @Binding var selectedDay: Int
    @Binding var windowStart: Int
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
                scrollToSelection(proxy, animated: false)
            }
            .onChange(of: selectedDay) {
                scrollToSelection(proxy, animated: true)
            }
        }
    }

    /// Aligns the rail with the chart window: day d at window position k
    /// lands at x = k*60 + 41, exactly as in the design.
    private func scrollToSelection(_ proxy: ScrollViewProxy, animated: Bool) {
        let k = min(max(selectedDay - windowStart, 0), 5)
        let anchor = UnitPoint(x: (27 + 60 * CGFloat(k)) / 365, y: 0.5)
        if animated {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(selectedDay, anchor: anchor)
            }
        } else {
            proxy.scrollTo(selectedDay, anchor: anchor)
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
