//
//  RootView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI

/// Animatable font size modifier using the modern @Animatable macro.
@Animatable
struct AnimatableCustomFontModifier: ViewModifier {
    var size: Double

    func body(content: Content) -> some View {
        content
            .font(.system(size: size))
    }
}

#Preview {
    RootView(model: AuthViewModel())
}

extension View {
    func animatableFont(size: Double) -> some View {
        modifier(AnimatableCustomFontModifier(size: size))
    }
}

/// Tab selection backed by an enum for type safety.
enum AppTab: Hashable {
    case owners
    case fleet
    case about
}

struct RootView: View {
    @Bindable var model: AuthViewModel
    @State private var selection: AppTab = .owners

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                Tab("Owners API", systemImage: "steeringwheel", value: .owners) {
                    OwnersAPIView(model: model)
                }
                Tab("Fleet API", systemImage: "car.2.fill", value: .fleet) {
                    FleetAPIView(model: model)
                }
                Tab("About", systemImage: "info.circle", value: .about) {
                    AboutView()
                }
            }
            .tint(Color("TeslaRed"))
        }
        .task {
            model.refreshAll()
        }
    }
}
