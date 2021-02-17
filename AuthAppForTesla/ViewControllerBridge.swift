//
//  ViewControllerBridge.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 17/02/2021.
//

import Foundation
import SwiftUI

struct ViewControllerBridge: UIViewControllerRepresentable {
    @Binding var isActive: Bool
    @Binding var parameter: String
    
    let action: (UIViewController, Bool, String) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        action(uiViewController, isActive, parameter)
    }
}
