//
//  AboutViewFriend.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import SafariServices
import StoreKit

struct AboutViewFriend: View {
    let name: String
    let appId: String?
    let appUrl: String?
    let icon: String

    @State var showSafari = false
    @State var showProduct = false
    @State var overlayAppID = ""
    @State var safariUrl = ""

    var body: some View {
        VStack{
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(12)
                .frame(width: 60)
            Text(name)
                .font(.system(size: 15, weight: .semibold, design: .default))
            
        }
        .padding()
        .cornerRadius(8)
        .shadow(radius: theme.shadow)

        .onTapGesture {
            if let appId = appId
            {
                overlayAppID = appId
                showProduct = true
            }
            else if let appUrl = appUrl
            {
                safariUrl = appUrl
                showSafari = true
            }
        }
        .background(
            Group {
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
                
                ViewControllerBridge(isActive: $showProduct, parameter: $overlayAppID) { vc, active, parameter in
                    if active {
                        let product = SKStoreProductViewController()
                        //product.delegate = context.coordinator
                        
                        let parameters = [ SKStoreProductParameterITunesItemIdentifier : parameter]
                        //isLoaded = false
                        product.loadProduct(withParameters: parameters) { (loaded, error) in
                            if loaded {
                                //      isLoaded = true
                            }
                        }
                        
                        vc.present(product, animated: true) {
                            // Set the variable to false when the user dismisses the VC
                            self.showProduct = false
                        }
                    }
                }
                .frame(width: 0, height: 0)
            }
        )
    }
}

struct AboutViewFriend_Previews: PreviewProvider {
    static var previews: some View {
        AboutViewFriend(name: "TeSlate", appId: nil, appUrl: "infinytum.co", icon: "TeSlate")
    }
}
