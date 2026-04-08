//
//  PreviewModelFactory.swift
//  AuthAppForTesla
//
//  In-memory AuthViewModel fixtures used by SwiftUI previews so we can
//  see populated states (token health, profiles, region badges, …)
//  without signing in to a real Tesla account.
//

#if DEBUG
import Foundation

@MainActor
enum PreviewModelFactory {
    /// A long-expired but realistically-shaped JWT used in previews.
    /// Header `{"alg":"HS256","typ":"JWT"}`
    /// Payload `{"iss":"https://auth.tesla.com/oauth2/v3","sub":"user-1","azp":"ownerapi","scp":["openid","email","offline_access","vehicle_device_data"],"iat":1735689600,"exp":1735776000,"ou_code":"NA","locale":"en-US"}`
    static let sampleAccessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2F1dGgudGVzbGEuY29tL29hdXRoMi92MyIsInN1YiI6InVzZXItMSIsImF6cCI6Im93bmVyYXBpIiwic2NwIjpbIm9wZW5pZCIsImVtYWlsIiwib2ZmbGluZV9hY2Nlc3MiLCJ2ZWhpY2xlX2RldmljZV9kYXRhIl0sImlhdCI6MTczNTY4OTYwMCwiZXhwIjoxNzM1Nzc2MDAwLCJvdV9jb2RlIjoiTkEiLCJsb2NhbGUiOiJlbi1VUyJ9.signature"

    static func sampleToken(prefix: String = "na") -> Token {
        Token(
            access_token: sampleAccessToken,
            token_type: "bearer",
            expires_in: 28800,
            refresh_token: "\(prefix)_sample_refresh_token_payload_for_previews",
            expires_at: Date().addingTimeInterval(7200),
            region: .global
        )
    }

    /// AuthViewModel populated with one Owners and one Fleet token, so
    /// HomeView and Tools previews show their populated states.
    static func populatedModel() -> AuthViewModel {
        let model = AuthViewModel()
        model.tokenV3 = sampleToken(prefix: "na")
        model.tokenV4 = sampleToken(prefix: "eu")
        model.profilesV3 = TokenProfileCollection(
            profiles: [TokenProfile(name: "Personal", token: sampleToken(prefix: "na"))],
            activeProfileId: nil
        )
        if let id = model.profilesV3.profiles.first?.id {
            model.profilesV3.activeProfileId = id
        }
        model.profilesV4 = TokenProfileCollection(
            profiles: [
                TokenProfile(name: "Work", token: sampleToken(prefix: "eu")),
                TokenProfile(name: "Test", token: sampleToken(prefix: "na"))
            ],
            activeProfileId: nil
        )
        if let id = model.profilesV4.profiles.first?.id {
            model.profilesV4.activeProfileId = id
        }
        return model
    }
}
#endif
