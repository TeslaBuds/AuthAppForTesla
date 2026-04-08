//
//  TestTokenView.swift
//  AuthAppForTesla
//
//  "Test your token" panel — runs a few read-only API calls so the
//  user can verify their stored token actually works end-to-end.
//

import SwiftUI

@MainActor
@Observable
final class TestTokenViewModel {
    var environment: LoginEnvironment = .owner
    var isRunning = false
    var results: [TestAPIResult] = []

    func run(model: AuthViewModel) async {
        guard !isRunning else { return }
        let token: Token? = environment == .owner ? model.tokenV3 : model.tokenV4
        guard let token else {
            results = []
            return
        }
        isRunning = true
        defer { isRunning = false }
        switch environment {
        case .owner:
            results = await TestAPIController.shared.runOwnersAPITests(token: token)
        case .fleet:
            results = await TestAPIController.shared.runFleetAPITests(token: token)
        }
    }
}

struct TestTokenView: View {
    @Bindable var model: AuthViewModel
    @State private var viewModel = TestTokenViewModel()

    private var hasToken: Bool {
        switch viewModel.environment {
        case .owner: model.tokenV3 != nil
        case .fleet: model.tokenV4 != nil
        }
    }

    var body: some View {
        Form {
            TestTokenEnvironmentSection(environment: $viewModel.environment)

            if hasToken {
                TestTokenRunSection(viewModel: viewModel, model: model)
                TestTokenResultsSection(results: viewModel.results, isRunning: viewModel.isRunning)
            } else {
                Section {
                    ContentUnavailableView(
                        "No token signed in",
                        systemImage: "key.slash",
                        description: Text("Sign in to the \(viewModel.environment == .owner ? "Owners" : "Fleet") API tab first.")
                    )
                }
            }
        }
        .navigationTitle("Test Token")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.environment) { _, _ in
            viewModel.results = []
        }
        .task {
            #if DEBUG
            if ScreenshotScenario.current == .testToken {
                viewModel.results = ScreenshotHarness.fakeOwnersTestResults
            }
            #endif
        }
    }
}

private struct TestTokenEnvironmentSection: View {
    @Binding var environment: LoginEnvironment

    var body: some View {
        Section("API") {
            Picker("API", selection: $environment) {
                Text("Owners API").tag(LoginEnvironment.owner)
                Text("Fleet API").tag(LoginEnvironment.fleet)
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct TestTokenRunSection: View {
    @Bindable var viewModel: TestTokenViewModel
    @Bindable var model: AuthViewModel

    var body: some View {
        Section {
            Button("Run Tests", systemImage: "play.fill") {
                Task { await viewModel.run(model: model) }
            }
            .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
            .foregroundStyle(.white)
            .disabled(viewModel.isRunning)
            .accessibilityIdentifier("runTestsButton")
            .frame(maxWidth: .infinity)
        }
    }
}

private struct TestTokenResultsSection: View {
    let results: [TestAPIResult]
    let isRunning: Bool

    var body: some View {
        if isRunning {
            Section {
                HStack {
                    ProgressView()
                    Text("Running tests…")
                }
            }
        } else if !results.isEmpty {
            Section("Results") {
                ForEach(results) { result in
                    TestTokenResultRow(result: result)
                }
            }
        }
    }
}

private struct TestTokenResultRow: View {
    let result: TestAPIResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .foregroundStyle(result.isSuccess ? .green : Color("TeslaRed"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title).bold()
                    Text(result.endpoint)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            if let summary = result.summary {
                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 28)
            }
            if case .failure(let code) = result.status, code > 0 {
                Text("HTTP \(code)")
                    .font(.caption2)
                    .foregroundStyle(Color("TeslaRed"))
                    .padding(.leading, 28)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("With Token") {
    NavigationStack {
        TestTokenView(model: PreviewModelFactory.populatedModel())
    }
}

#Preview("Empty") {
    NavigationStack {
        TestTokenView(model: AuthViewModel())
    }
}
