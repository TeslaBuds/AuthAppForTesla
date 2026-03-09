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
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .shadow(radius: 8, y: 4)
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
                    .padding(.bottom, 24)
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

#Preview {
    VStack {
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.gray.opacity(0.2))
    .toast(.constant(.error("Failed to refresh token. Please sign in again.")))
}
