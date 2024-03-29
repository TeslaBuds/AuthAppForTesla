//
//  RootView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import SwiftUI
import Combine
import SwiftDate

// A modifier that animates a font through various sizes.
struct AnimatableCustomFontModifier: AnimatableModifier {
    var size: CGFloat
    
    var animatableData: CGFloat {
        get { size }
        set { size = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size))
    }
}

// To make that easier to use, I recommend wrapping
// it in a `View` extension, like this:
extension View {
    func animatableFont(size: CGFloat) -> some View {
        self.modifier(AnimatableCustomFontModifier(size: size))
    }
}


struct RootView: View {
    @ObservedObject var model: AuthViewModel
    @State private var selection = 0
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                OwnersAPIView(model: model)
                    .font(.title)
                    .tabItem {
                        VStack {
                            Image(systemName: "steeringwheel")
                            Text("Owners API")
                        }
                    }
                    .tag(0)
                FleetAPIView(model: model)
                    .font(.title)
                    .tabItem {
                        VStack {
                            Image(systemName: "car.2.fill")
                            Text("Fleet API")
                        }
                    }
                    .tag(1)
                AboutView()
                    .font(.title)
                    .tabItem {
                        VStack {
                            Image(systemName: "info.circle")
                            Text("About")
                        }
                    }
                    .tag(2)
            }
            .accentColor(Color("TeslaRed"))
        }
        .onAppear(perform: {
            model.refreshAll()
        })
    }
    
}
