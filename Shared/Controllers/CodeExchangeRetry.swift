//
//  CodeExchangeRetry.swift
//  AuthAppForTesla
//
//  #60: the sign-in code exchange retries a lost connection or a 5xx with a
//  short, bounded backoff instead of firing the retries back to back.
//

import Foundation

/// How the OAuth code exchange retries: at most `maxRetries` extra tries,
/// waiting `initialDelay`, then twice that, and so on, before each one.
struct CodeExchangeRetry: Sendable {
    /// 3 retries after 0.5 s, 1 s and 2 s: an offline sign-in gives up
    /// after about 3.5 s instead of four requests in a few milliseconds.
    static let standard = CodeExchangeRetry(maxRetries: 3, initialDelay: .milliseconds(500))

    let maxRetries: Int
    let initialDelay: Duration

    /// The pause before retry number `retry` (1-based).
    func delay(beforeRetry retry: Int) -> Duration {
        initialDelay * (1 << max(0, retry - 1))
    }

    /// Runs `attempt` until it succeeds, fails in a way `isRetryable`
    /// rejects, the retries run out, or the task is cancelled. `attempt`
    /// gets the 0-based attempt number.
    func run(
        isRetryable: (FailureDataResponse) -> Bool,
        sleep: (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
        attempt: (Int) async -> DataResult
    ) async -> DataResult {
        var number = 0
        while true {
            let result = await attempt(number)
            guard case .failure(let failure) = result,
                  isRetryable(failure),
                  number < maxRetries else { return result }
            number += 1
            do {
                try await sleep(delay(beforeRetry: number))
            } catch {
                return result
            }
        }
    }
}
