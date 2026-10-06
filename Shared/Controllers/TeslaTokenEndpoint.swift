//
//  TeslaTokenEndpoint.swift
//  AuthAppForTesla
//
//  The live refresh transport: posts a refresh token to Tesla's
//  `/oauth2/v3/token` and sorts the answer into token / refused /
//  unavailable (AuthAppForTesla#48–#50).
//

import Foundation
import TeslaAuthKit

struct TeslaTokenEndpoint: TokenRefreshTransport {
    func refresh(refreshToken: String, region: TokenRegion, environment: LoginEnvironment) async -> TokenEndpointResponse {
        let host = switch region {
        case .global: "https://auth.tesla.com"
        case .china: "https://auth.tesla.cn"
        }
        let parameters: [String: Any] = switch environment {
        case .owner:
            ["grant_type": "refresh_token",
             "scope": "openid email offline_access",
             "client_id": "ownerapi",
             "refresh_token": refreshToken]
        case .fleet:
            ["grant_type": "refresh_token",
             "client_id": KeychainWrapper.global.string(forKey: kFleetClientID) ?? "",
             "refresh_token": refreshToken]
        }
        let result = await NetworkController.shared.post("\(host)/oauth2/v3/token", parameters: parameters)
        return Self.classify(result, region: region)
    }

    static func classify(_ result: DataResult, region: TokenRegion) -> TokenEndpointResponse {
        switch result {
        case .success(let response):
            return .classify(statusCode: response.statusCode, body: response.data, transportError: nil, region: region)
        case .failure(let response):
            let transportError: Error? = response.fullResponse == nil ? response.error : nil
            return .classify(
                statusCode: response.fullResponse?.statusCode,
                body: response.data,
                transportError: transportError,
                region: region
            )
        }
    }
}
