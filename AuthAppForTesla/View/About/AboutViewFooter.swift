//
//  AboutViewFooter.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct AboutViewFooter: View {
    private var columns: [GridItem] = [
        GridItem(.fixed(150), spacing: 8),
        GridItem(.fixed(150), spacing: 8),
    ]
    
    let friends = [
        Friend(name: "Watch app for Tesla", appId: "1512108917", appUrl: nil, icon: "WatchAppForTesla"),
        Friend(name: "TeSlate", appId: "1532406445", appUrl: nil, icon: "TeSlate"),
        Friend(name: "Charged — for Tesl‪a", appId: "1444906703", appUrl: nil, icon: "Charged"),
        Friend(name: "Teslascope", appId: nil, appUrl: "https://teslascope.com", icon: "TeslaScope"),
        Friend(name: "Tesla iOS Shortcuts", appId: nil, appUrl: "https://github.com/dburkland/tesla_ios_shortcuts/blob/master/README.md", icon: "tesla_ios_shortcuts")
    ]
    
    var body: some View {
        VStack{
            ScrollView {
            Text("Friends of the App")
                .font(.system(size: 30, weight: .regular, design: .default))
                .padding(.bottom, -5)
            LazyVGrid(
                columns: columns,
                alignment: .center,
                spacing: 0
            ) {
                ForEach(friends.shuffled(), id: \.name) { friend in
                    AboutViewFriend(name: friend.name, appId: friend.appId, appUrl: friend.appUrl, icon: friend.icon)
                        .frame(height: 140, alignment: .top)
                        .multilineTextAlignment(.center)
                }
            }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom)
        .padding(.top, 15)
        .background(Color("SheetColor").shadow(radius: 6))
    }
}

struct Friend {
    let name: String
    let appId: String?
    let appUrl: String?
    let icon: String
}

struct AboutViewFooter_Previews: PreviewProvider {
    static var previews: some View {
        AboutViewFooter()
    }
}
