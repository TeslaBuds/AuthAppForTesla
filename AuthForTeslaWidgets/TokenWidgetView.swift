//
//  TokenWidgetView.swift
//  AuthForTeslaWidgets
//

import SwiftUI
import WidgetKit

/// The widget's root view: one token on the small widget, both on the medium.
struct TokenWidgetView: View {
    let entry: TokenWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallTokenWidgetView(entry: entry)
            default:
                MediumTokenWidgetView(entry: entry)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

/// The two APIs the app signs in to.
enum TokenAPI: CaseIterable {
    case owners, fleet

    var title: LocalizedStringKey {
        switch self {
        case .owners: "Owners API"
        case .fleet: "Fleet API"
        }
    }

    var systemImage: String {
        switch self {
        case .owners: "steeringwheel"
        case .fleet: "car.2.fill"
        }
    }

    func status(in entry: TokenWidgetEntry) -> TokenStatus {
        switch self {
        case .owners: entry.owners
        case .fleet: entry.fleet
        }
    }
}

/// Small widget: the app icon and the Owners API token, or the Fleet API
/// token when only that one is signed in.
struct SmallTokenWidgetView: View {
    let entry: TokenWidgetEntry

    private var api: TokenAPI {
        entry.owners == .signedOut && entry.fleet != .signedOut ? .fleet : .owners
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image("SetupIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .clipShape(.rect(cornerRadius: 6))
                    .accessibilityHidden(true)
                Spacer()
                TokenUrgencySymbol(urgency: api.status(in: entry).urgency(at: entry.date))
            }
            Spacer(minLength: 0)
            TokenAPILabel(api: api)
            TokenExpiryView(status: api.status(in: entry), date: entry.date)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// Medium widget: both tokens side by side.
struct MediumTokenWidgetView: View {
    let entry: TokenWidgetEntry

    var body: some View {
        HStack {
            TokenColumnView(api: .owners, entry: entry)
            Divider()
            TokenColumnView(api: .fleet, entry: entry)
        }
    }
}

/// One API's name, urgency symbol and expiry.
struct TokenColumnView: View {
    let api: TokenAPI
    let entry: TokenWidgetEntry

    var body: some View {
        let status = api.status(in: entry)
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                TokenAPILabel(api: api)
                Spacer(minLength: 0)
                TokenUrgencySymbol(urgency: status.urgency(at: entry.date))
            }
            Spacer(minLength: 0)
            TokenExpiryView(status: status, date: entry.date)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct TokenAPILabel: View {
    let api: TokenAPI

    var body: some View {
        Label(api.title, systemImage: api.systemImage)
            .font(.caption)
            .bold()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

/// The same seal and octagon symbols the app's token badge uses.
struct TokenUrgencySymbol: View {
    let urgency: TokenStatus.Urgency

    var body: some View {
        switch urgency {
        case .signedOut:
            Image(systemName: "person.crop.circle.badge.questionmark")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Not signed in")
        case .valid:
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .widgetAccentable()
                .accessibilityLabel("Valid")
        case .expiringSoon:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .widgetAccentable()
                .accessibilityLabel("Expiring soon")
        case .expired:
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(Color("TeslaRed"))
                .widgetAccentable()
                .accessibilityLabel("Expired")
        }
    }
}

/// How long a token has left, or how long ago it expired.
struct TokenExpiryView: View {
    let status: TokenStatus
    let date: Date

    var body: some View {
        switch (status.urgency(at: date), status.expiresAt) {
        case (.signedOut, _):
            Text("Not signed in")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case (.expired, let expiresAt?):
            VStack(alignment: .leading) {
                Text("Expired")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(Color("TeslaRed"))
                    .widgetAccentable()
                Text("\(expiresAt, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case (let urgency, let expiresAt?):
            VStack(alignment: .leading) {
                Text("Expires in")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(expiresAt, style: .relative)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(urgency == .expiringSoon ? Color.orange : Color.green)
                    .widgetAccentable()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        case (_, nil):
            Text("Signed in")
                .font(.title3)
                .bold()
                .foregroundStyle(.green)
                .widgetAccentable()
        }
    }
}

// MARK: - Previews

private extension TokenWidgetEntry {
    static let previewMixed = TokenWidgetEntry(
        date: .now,
        owners: .signedIn(expiresAt: .now.addingTimeInterval(1_500)),
        fleet: .signedIn(expiresAt: .now.addingTimeInterval(-3_000))
    )

    static let previewSignedOut = TokenWidgetEntry(date: .now, owners: .signedOut, fleet: .signedOut)
}

#Preview("Small", as: .systemSmall) {
    TokenWidget()
} timeline: {
    TokenWidgetEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    TokenWidget()
} timeline: {
    TokenWidgetEntry.placeholder
}

#Preview("Small, expiring soon", as: .systemSmall) {
    TokenWidget()
} timeline: {
    TokenWidgetEntry.previewMixed
}

#Preview("Medium, expiring and expired", as: .systemMedium) {
    TokenWidget()
} timeline: {
    TokenWidgetEntry.previewMixed
}

#Preview("Small, signed out", as: .systemSmall) {
    TokenWidget()
} timeline: {
    TokenWidgetEntry.previewSignedOut
}

#Preview("Medium, signed out", as: .systemMedium) {
    TokenWidget()
} timeline: {
    TokenWidgetEntry.previewSignedOut
}
