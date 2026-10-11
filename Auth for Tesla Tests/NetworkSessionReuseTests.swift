//
//  NetworkSessionReuseTests.swift
//  Auth for Tesla Tests
//
//  #60: one URLSession per NetworkController, so requests share a
//  connection pool; the code exchange backs off between retries.
//

import Testing
import Foundation
import Synchronization
@testable import AuthAppForTesla

/// Records each request's task identifier. Identifiers count up from 1
/// within one URLSession, so a new session per request shows as 1, 1, 1.
final class TaskIdentifierRecorder: URLProtocol {
    static let identifiers = Mutex<[Int]>([])

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canInit(with task: URLSessionTask) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let id = task?.taskIdentifier {
            Self.identifiers.withLock { $0.append(id) }
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("{}".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// Records the pauses the retry would take, without waiting.
final class PauseRecorder: Sendable {
    private let pauses = Mutex<[Duration]>([])
    var value: [Duration] { pauses.withLock { $0 } }
    func record(_ pause: Duration) { pauses.withLock { $0.append(pause) } }
}

@Suite("Network session reuse and sign-in backoff (#60)", .serialized)
struct NetworkSessionReuseTests {
    @Test("Requests on one controller share one URLSession")
    func requestsShareOneSession() async {
        TaskIdentifierRecorder.identifiers.withLock { $0 = [] }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TaskIdentifierRecorder.self]
        let network = NetworkController(configuration: configuration)

        _ = await network.post("https://auth.tesla.com/oauth2/v3/token", parameters: ["grant_type": "stub"])
        _ = await network.get("https://auth.tesla.com/stub")
        _ = await network.post("https://auth.tesla.com/oauth2/v3/token", parameters: ["grant_type": "stub"])

        let identifiers = TaskIdentifierRecorder.identifiers.withLock { $0 }
        let sessions = identifiers.count(where: { $0 == 1 })
        #expect(identifiers.count == 3)
        #expect(sessions == 1, "3 requests used \(sessions) sessions (before #60: 3); ids \(identifiers)")
    }

    @Test("Offline code exchange: 4 tries, backing off 0.5 s, 1 s, 2 s")
    func offlineExchangeBacksOff() async {
        let pauses = PauseRecorder()
        let attempts = Mutex(0)
        let result = await CodeExchangeRetry.standard.run(
            isRetryable: AuthController.isRetryable,
            sleep: { pauses.record($0) }
        ) { _ in
            attempts.withLock { $0 += 1 }
            return DataResult(data: nil, response: nil, error: URLError(.notConnectedToInternet) as NSError)
        }
        #expect(result.error != nil)
        #expect(attempts.withLock { $0 } == 4)
        #expect(pauses.value == [.milliseconds(500), .seconds(1), .seconds(2)], "before #60: no pause at all")
    }

    @Test("A 4xx is final: one try, no pause")
    func clientErrorIsNotRetried() async {
        let pauses = PauseRecorder()
        let attempts = Mutex(0)
        let url = URL(string: "https://auth.tesla.com/oauth2/v3/token")!
        _ = await CodeExchangeRetry.standard.run(
            isRetryable: AuthController.isRetryable,
            sleep: { pauses.record($0) }
        ) { _ in
            attempts.withLock { $0 += 1 }
            return DataResult(data: Data(#"{"error":"invalid_grant"}"#.utf8),
                              response: HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: nil),
                              error: nil)
        }
        #expect(attempts.withLock { $0 } == 1)
        #expect(pauses.value.isEmpty)
    }

    @Test("A 5xx that recovers stops retrying at the success")
    func serverErrorThenSuccess() async {
        let pauses = PauseRecorder()
        let attempts = Mutex(0)
        let url = URL(string: "https://auth.tesla.com/oauth2/v3/token")!
        let result = await CodeExchangeRetry.standard.run(
            isRetryable: AuthController.isRetryable,
            sleep: { pauses.record($0) }
        ) { attempt in
            attempts.withLock { $0 += 1 }
            return DataResult(data: Data("{}".utf8),
                              response: HTTPURLResponse(url: url, statusCode: attempt == 0 ? 503 : 200, httpVersion: nil, headerFields: nil),
                              error: nil)
        }
        #expect(result.error == nil)
        #expect(attempts.withLock { $0 } == 2)
        #expect(pauses.value == [.milliseconds(500)])
    }

    @Test("Cancelling the sign-in stops the retries")
    func cancellationStopsRetries() async {
        let attempts = Mutex(0)
        _ = await CodeExchangeRetry.standard.run(
            isRetryable: AuthController.isRetryable,
            sleep: { _ in throw CancellationError() }
        ) { _ in
            attempts.withLock { $0 += 1 }
            return DataResult(data: nil, response: nil, error: URLError(.notConnectedToInternet) as NSError)
        }
        #expect(attempts.withLock { $0 } == 1)
    }
}
