//
//  ToastView.swift
//  AuthAppForTesla
//

import SwiftUI
import TeslaAuthKit

/// Renders a single snackbar notification that can be swiped down to dismiss.
struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.systemImage)
                .foregroundStyle(toast.style.tint)
                .imageScale(.large)
            Text(toast.message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Button("Dismiss", systemImage: "xmark", action: onDismiss)
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
                .imageScale(.small)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal)
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.height > 0 {
                        onDismiss()
                    }
                }
        )
    }
}

/// Overlay modifier that displays a `Toast` and auto-dismisses after a
/// delay. With VoiceOver running it stays until dismissed, so it can be
/// found and read; it is announced when shown either way (#57).
struct ToastOverlayModifier: ViewModifier {
    @Binding var toast: Toast?

    /// On iOS the toast is attached to each tab's content, whose safe area
    /// already ends at the tab bar — at the bottom on a phone, at the side
    /// on the iPhone Duo's outer display, at the top on iPad — so a small
    /// gap is all it needs (#66). The Mac window has no tab bar; the toast
    /// keeps the room it always had above the window's bottom edge.
    #if os(iOS)
    private static let bottomMargin = AppSpacing.sm
    #else
    private static let bottomMargin: CGFloat = 75
    #endif

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast {
                    ToastView(toast: toast) {
                        withAnimation(.spring) {
                            self.toast = nil
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        )
                    )
                    .padding(.bottom, Self.bottomMargin)
                    .task(id: toast.id) {
                        guard !voiceOverEnabled else { return }
                        try? await Task.sleep(for: .seconds(4))
                        withAnimation(.spring) {
                            if self.toast?.id == toast.id {
                                self.toast = nil
                            }
                        }
                    }
                }
            }
            .animation(.spring, value: toast?.id)
    }
}

extension View {
    /// Attaches a toast overlay that auto-dismisses after ~4 seconds
    /// (not while VoiceOver is running).
    func toast(_ toast: Binding<Toast?>) -> some View {
        modifier(ToastOverlayModifier(toast: toast))
    }
}

#Preview("Error toast over TabView") {
    TabView {
        Tab("Owners API", systemImage: "steeringwheel") {
            ZStack {
                LinearGradient(
                    colors: [.indigo.opacity(0.4), .purple.opacity(0.3)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
                VStack {
                    Text("Owners API content")
                        .font(.title2)
                    Spacer()
                }
                .padding(.top, 80)
            }
        }
        Tab("Fleet API", systemImage: "car.2.fill") { Color.gray }
        Tab("Tools", systemImage: "wrench.and.screwdriver") { Color.gray }
        Tab("About", systemImage: "info.circle") { Color.gray }
    }
    .tint(.red)
    .toast(.constant(.error("Failed to refresh token. Please sign in again.")))
}

#Preview("Success toast over TabView") {
    TabView {
        Tab("Owners API", systemImage: "steeringwheel") {
            ZStack {
                LinearGradient(
                    colors: [.indigo.opacity(0.4), .purple.opacity(0.3)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
        Tab("Fleet API", systemImage: "car.2.fill") { Color.gray }
    }
    .tint(.red)
    .toast(.constant(.success("Tokens refreshed successfully.")))
}
