//
//  LicenseEntry.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct LicenseViewEntry: View {
    var author: String
    var name: String
    var link: String
    var license: String = ""
    
    var body: some View {
        VStack(alignment: .center) {
            Text(name)
                .font(.system(.title))
            Text(author)
                .font(.system(.title2))
            Text(license)
                .font(.system(.footnote))
                .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
        }.padding(.bottom, 20)
    }
}

struct LicenseViewEntry_Previews: PreviewProvider {
    static var previews: some View {
        LicenseViewEntry(author: "Me", name: "Great Library", link: "https://github/superduper/library")
    }
}
