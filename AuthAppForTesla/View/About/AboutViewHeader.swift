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
            Text("© 2021 Kim Hansen, Michael Teuscher")
                .font(.system(size: 15, weight: .semibold, design: .default))
            
            VStack {
                Text("About to buy a new Tesla?")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                Text("Use my referral code!")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                Text("https://ts.la/kim85428")
                    .font(.system(size: 15, weight: .semibold, design: .default))
            }
            .padding(.top, 1)
            .onTapGesture {
                safariUrl = "https://ts.la/kim85428"
                showSafari = true
            }
            .background(
                ViewControllerBridge(isActive: $showSafari, parameter: $safariUrl) { vc, active, parameter in
                    if active {
                        let safariVC = SFSafariViewController(url: URL(string: parameter)!)
                        vc.present(safariVC, animated: true) {
                            // Set the variable to false when the user dismisses the safari VC
                            self.showSafari = false
                        }
                    }
                }
                .frame(width: 0, height: 0)
            )

            
            Text("Open Source Licenses")
                .font(.system(size: 15, weight: .semibold, design: .default))
                .foregroundColor(Color("TeslaRed"))
                .padding(.top, 5)
                .onTapGesture {
                    selection = "License"
                }
            Spacer()
            NavigationLink(destination: LicenseView(), tag: "License", selection: $selection) { EmptyView() }
                .navigationBarTitle("Settings", displayMode: .inline)
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom)
    }
}

struct AboutViewHeader_Previews: PreviewProvider {
    static var previews: some View {
        AboutViewHeader()
    }
}
