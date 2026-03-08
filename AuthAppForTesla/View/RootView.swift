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

#Preview("Owners API") {
    RootView(model: AuthViewModel(), initialTab: .owners)
}

#Preview("Fleet API") {
    RootView(model: AuthViewModel(), initialTab: .fleet)
}

#Preview("About") {
    RootView(model: AuthViewModel(), initialTab: .about)
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
    @State private var selection: AppTab

    init(model: AuthViewModel, initialTab: AppTab = .owners) {
        self.model = model
        _selection = State(initialValue: initialTab)
    }

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
            #if DEBUG
            guard !CommandLine.arguments.contains("enable-testing") else { return }
            #endif
            model.refreshAll()
        }
    }
}
