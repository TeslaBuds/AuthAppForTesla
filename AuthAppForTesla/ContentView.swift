//
//  ContentView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import SwiftUI
import Combine
import OAuthSwift
import SwiftDate
import Networking


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


struct ContentView: View {
    @ObservedObject var model: AuthViewModel
    @State private var selection = 0
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    var body: some View {
        if (model.tokenV3?.refresh_token.count ?? 0 == 0) ||
           (model.externalTokenRequest != nil)
        {
            SetupView(model: model).frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom)
        } else {
            TabView(selection: $selection) {
                HomeView(model: model)
                    .font(.title)
                    .tabItem {
                        VStack {
                            Image(systemName: "house")
                            Text("Home")
                        }
                    }
                    .tag(0)
                AboutView()
                    .font(.title)
                    .tabItem {
                        VStack {
                            Image(systemName: "info.circle")
                            Text("About")
                        }
                    }
                    .tag(1)
            }
        }
        
    }
    
}
