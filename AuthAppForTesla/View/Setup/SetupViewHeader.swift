//
//  SetupViewHeader.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

struct SetupViewHeader: View {
    var body: some View {
        VStack{
            Spacer()
            Image("SetupIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .cornerRadius(10.0)
                .shadow(radius: 6)
            Text("Auth for Tesla")
                .font(.system(size: 35, weight: .bold, design: .default))
            Spacer()
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom)
    }
}

struct SetupViewHeader_Previews: PreviewProvider {
    static var previews: some View {
        SetupViewHeader()
    }
}
