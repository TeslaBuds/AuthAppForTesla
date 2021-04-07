//
//  IconBackgroundView.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

struct IconBackgroundView<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    var content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack(alignment: .topLeading){
                    VStack {
                        Image(colorScheme == .dark ? "IconPatternDark" : "IconPattern")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom)
                    VStack(content: content)
                }
            }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom)
        }.edgesIgnoringSafeArea(.top)//.edgesIgnoringSafeArea(.bottom)
    }
}

struct IconBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        IconBackgroundView() {
            Text("Hello Love")
        }
    }
}
