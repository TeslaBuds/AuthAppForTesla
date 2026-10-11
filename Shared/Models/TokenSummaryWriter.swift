//
//  TokenSummaryWriter.swift
//  AuthAppForTesla
//
//  #52: the widget summary follows the token store, whoever changed it.
//  A Shortcut refreshing a token at night updates the widget and the Mac
//  menu bar without the app being opened.
//

import Foundation

/// Publishes the widget's token summary after every change to the token
/// store, through #58's `TokenSummaryPublisher` (which writes and reloads
/// the widget only when the summary actually changed).
///
/// Coalesced: a request made while a write is waiting to start joins it,
/// and one made while a write is reading the store causes exactly one
/// more pass afterwards, so the last change is always the one published.
actor TokenSummaryWriter {
    private let publisher: TokenSummaryPublisher
    private var running: Task<Void, Never>?
    private var isReading = false
    private var needsAnotherPass = false

    /// How many times the store was read and the summary offered to the
    /// publisher. Tests use it to see requests coalesce.
    private(set) var passes = 0

    init(publisher: TokenSummaryPublisher) {
        self.publisher = publisher
    }

    /// The real App Group suite and the real widget.
    static let live = TokenSummaryWriter(publisher: .live)

    /// The summary currently stored for the widget.
    var stored: TokenSummary? { publisher.stored }

    /// Publishes the summary `read` returns, joining a write already
    /// pending. Await the task to know the store's current state is out.
    @discardableResult
    func update(reading read: @escaping @Sendable () async -> TokenSummary) -> Task<Void, Never> {
        if let running {
            if isReading { needsAnotherPass = true }
            return running
        }
        let task = Task { await self.run(read) }
        running = task
        return task
    }

    private func run(_ read: @Sendable () async -> TokenSummary) async {
        repeat {
            needsAnotherPass = false
            isReading = true
            let summary = await read()
            isReading = false
            passes += 1
            publisher.publish(summary)
        } while needsAnotherPass
        running = nil
    }
}
