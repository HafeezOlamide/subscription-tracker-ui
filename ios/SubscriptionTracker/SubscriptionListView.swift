import SwiftUI

struct SubscriptionListView: View {
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            cards
        }
        .padding(20)
        .frame(width: 393)
    }

    private var header: some View {
        HStack {
            Text("Upcoming Renewals")
                .font(AppFont.geistMedium(14))
                .foregroundStyle(Palette.sectionLabel)
            Spacer()
            Button {
            } label: {
                HStack(spacing: 4) {
                    Text("See all subscriptions")
                        .font(AppFont.interMedium(14))
                        .foregroundStyle(Palette.ink)
                    Image("chevron-right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
            .buttonStyle(.plain)
        }
    }

    private var cards: some View {
        VStack(spacing: 0) {
            ForEach(Array(subscriptions.enumerated()), id: \.element.id) { index, sub in
                if index > 0 {
                    Rectangle()
                        .fill(Palette.separator)
                        .frame(height: 1)
                }
                if index == 0 {
                    // iCloud+ expands to the detail card from the design
                    Group {
                        if expanded {
                            ExpandedCard(subscription: sub) { toggle() }
                                .transition(.opacity)
                        } else {
                            SubscriptionRow(subscription: sub) { toggle() }
                                .transition(.opacity)
                        }
                    }
                } else {
                    SubscriptionRow(subscription: sub, onToggle: nil)
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 10)
    }

    private func toggle() {
        withAnimation(.easeInOut(duration: 0.32)) { expanded.toggle() }
    }
}

struct SubscriptionRow: View {
    let subscription: Subscription
    var onToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                BrandIcon(subscription: subscription)
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(AppFont.geistMedium(14))
                        .foregroundStyle(Palette.ink)
                    Text(subscription.renews)
                        .font(AppFont.geistMedium(14))
                        .foregroundStyle(Palette.secondary)
                }
                Spacer(minLength: 16)
                Text(subscription.price)
                    .font(AppFont.geistSemiBold(14))
                    .foregroundStyle(Palette.ink)
            }
            Image("chevron-down")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .padding(.vertical, 12)
        }
        .padding(.leading, 16)
        .padding(.trailing, 24)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .onTapGesture { onToggle?() }
    }
}

struct ExpandedCard: View {
    let subscription: Subscription
    var onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                BrandIcon(subscription: subscription)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iCloud+")
                            .font(AppFont.geistMedium(18))
                            .foregroundStyle(Palette.ink)
                        Text("iCloud+ with 200GB of storage")
                            .font(AppFont.geistMedium(14))
                            .foregroundStyle(Palette.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("$2.99")
                                .font(AppFont.geistMedium(14))
                                .foregroundStyle(Palette.ink)
                            Text("per month")
                                .font(AppFont.geistMedium(14))
                                .foregroundStyle(Palette.secondary)
                        }
                        Text("Renews 24 June")
                            .font(AppFont.geistMedium(14))
                            .foregroundStyle(Palette.ink)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Button {
                    } label: {
                        HStack(spacing: 4) {
                            Text("See all plans")
                                .font(AppFont.interMedium(14))
                                .foregroundStyle(Palette.ink)
                            Image("chevron-down")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(Palette.pill))
                    }
                    .buttonStyle(.plain)

                    Button {
                    } label: {
                        Text("Cancel Subscription")
                            .font(AppFont.interMedium(14))
                            .foregroundStyle(Palette.cancelRed)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Capsule().fill(Palette.pill))
                    }
                    .buttonStyle(.plain)

                    Button {
                    } label: {
                        Text("About subscriptions and privacy")
                            .font(AppFont.interMedium(14))
                            .foregroundStyle(Palette.ink)
                            .underline()
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
            Image("chevron-down")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .scaleEffect(y: -1)
                .padding(.vertical, 12)
                .contentShape(Rectangle().inset(by: -8))
                .onTapGesture { onToggle() }
        }
        .padding(.leading, 16)
        .padding(.trailing, 24)
        .padding(.vertical, 16)
    }
}

struct BrandIcon: View {
    let subscription: Subscription

    var body: some View {
        Circle()
            .fill(Palette.iconCircle)
            .frame(width: 40, height: 40)
            .overlay {
                Image(subscription.icon)
                    .resizable()
                    .frame(width: subscription.iconSize.width, height: subscription.iconSize.height)
            }
    }
}
