//
//  ToastView.swift
//  AuthAppForTesla
//

import SwiftUI

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

/// Overlay modifier that displays a `Toast` and auto-dismisses after a delay.
struct ToastOverlayModifier: ViewModifier {
    @Binding var toast: Toast?

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
                    // Clear the iOS 26 floating tab bar capsule by a
                    // hair: tab bar is ~75pt tall, sits ~10pt below
                    // the safe area, and the toast itself is ~50pt
                    // tall, so 75pt of bottom padding leaves a
                    // ~10pt gap above the tab bar's rounded top.
                    // Hardcoding the offset is fine here: the toast is
                    // only ever shown inside the RootView TabView
                    // hierarchy on iPhone — on iPad the tab bar is
                    // top-mounted, where the extra bottom padding
                    // just gives the toast room to breathe.
                    .padding(.bottom, 75)
                    .task(id: toast.id) {
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
    /// Attaches a toast overlay that auto-dismisses after ~4 seconds.
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
