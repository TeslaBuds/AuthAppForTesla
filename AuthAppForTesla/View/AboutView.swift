//
//  AboutView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationView {
            IconBackgroundView{
                ScrollView {
                    AboutViewHeader()
                        .padding(.top, 50)
                    Spacer()
                    AboutViewFooter()
                }
            }.navigationViewStyle(StackNavigationViewStyle())
                .navigationBarTitle("")
                .navigationBarHidden(true)
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
