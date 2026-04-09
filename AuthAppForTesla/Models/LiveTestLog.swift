//
//  LiveTestLog.swift
//  AuthAppForTesla
//
//  Live UI test diagnostic log. xcodebuild runs UI tests on an ephemeral
//  cloned simulator that gets deleted after the test, so `simctl log
//  show` can't reach it. To get OAuth diagnostics out of a failing live
//  test, the app appends events to this in-memory accumulator and a
//  hidden Text view in the root view exposes the joined log via an
//  accessibility identifier. The UI test reads that label and attaches
//  it to the test result bundle.
//

#if DEBUG
import Foundation
import Observation

@Observable
final class LiveTestLog {
    static let shared = LiveTestLog()

    private(set) var entries: [String] = []

    /// Whether the live-test launch flag is set. Production runs don't
    /// pay any cost beyond a single CommandLine check at startup.
    static let isActive: Bool = CommandLine.arguments.contains("live-test-clear-state")

    private init() {}

    func append(_ message: String) {
        guard Self.isActive else { return }
        let stamp = Self.timestamp()
        let line = "[\(stamp)] \(message)"
        if Thread.isMainThread {
            entries.append(line)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.entries.append(line)
            }
        }
    }

    var joined: String {
        entries.joined(separator: "\n")
    }

    private static func timestamp() -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: now)
    }
}
#endif
