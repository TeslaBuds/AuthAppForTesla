//
//  AboutViewHeader.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import SafariServices

struct AboutViewHeader: View {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

    @State private var selection: String? = nil
    @State var showSafari = false
    @State var safariUrl = ""
    @State private var isLicenseViewPresented = false

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
                .padding(.bottom, 0.5)
            Text("v. \(version) build \(build)")
                .font(.system(size: 15, weight: .semibold, design: .default))
            Text("© 2024 Kim Hansen, Michael Teuscher")
                .font(.system(size: 15, weight: .semibold, design: .default))
            Text("Open Source Licenses")
                .font(.system(size: 15, weight: .semibold, design: .default))
                .foregroundColor(Color("TeslaRed"))
                .padding(.top, 5)
                .onTapGesture {
                    isLicenseViewPresented = true
//                    selection = "License"
                }
            Spacer()
//            NavigationLink(destination: LicenseView(), tag: "License", selection: $selection) { EmptyView() }
                .navigationBarTitle("Settings", displayMode: .inline)
                .navigationDestination(isPresented: $isLicenseViewPresented) {
                                LicenseView()
                            }
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom)
    }
}

struct AboutViewHeader_Previews: PreviewProvider {
    static var previews: some View {
        AboutViewHeader()
    }
}
