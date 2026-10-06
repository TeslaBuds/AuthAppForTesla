//
//  OAuthRedirectTests.swift
//  TeslaAuthKitTests
//
//  The redirect's `state` must match before a code is handed out (#51).
//

import Testing
import Foundation
@testable import TeslaAuthKit

@Suite("OAuth redirect state validation")
struct OAuthRedirectTests {
    private func url(_ query: String) -> URL {
        URL(string: "tesla://auth/callback?\(query)")!
    }

    @Test("A matching state yields the code")
    func matchingState() {
        let result = OAuthRedirect.authorizationCode(from: url("code=NA_abc&state=s1&issuer=x"), expectedState: "s1")
        #expect(result == .success("NA_abc"))
    }

    @Test("A different state is refused, so no code is exchanged")
    func mismatchedState() {
        #expect(OAuthRedirect.authorizationCode(from: url("code=NA_abc&state=attacker"), expectedState: "s1") == .failure(.stateMismatch))
    }

    @Test("A missing state is refused")
    func missingState() {
        #expect(OAuthRedirect.authorizationCode(from: url("code=NA_abc"), expectedState: "s1") == .failure(.stateMismatch))
    }

    @Test("An empty expected state never matches")
    func emptyExpectedState() {
        #expect(OAuthRedirect.authorizationCode(from: url("code=NA_abc&state="), expectedState: "") == .failure(.stateMismatch))
    }

    @Test("A matching state without a code reports the missing code")
    func missingCode() {
        #expect(OAuthRedirect.authorizationCode(from: url("state=s1"), expectedState: "s1") == .failure(.missingCode))
    }

    @Test("An OAuth error in the redirect is reported")
    func authorizationError() {
        let result = OAuthRedirect.authorizationCode(from: url("error=access_denied&error_description=Denied&state=s1"), expectedState: "s1")
        #expect(result == .failure(.authorizationError("Denied")))
    }
}
