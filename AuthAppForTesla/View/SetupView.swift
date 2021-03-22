//
//  SetupView.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

struct SetupView: View {
    @ObservedObject var model: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        IconBackgroundView{
            SetupViewHeader()
            Spacer()
            SetupViewFooter(model: model)
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView(model: AuthViewModel())
    }
}
