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
        IconBackgroundView {
            ScrollView {
                VStack(spacing: AppSpacing.cardGap) {
                    TestTokenHeaderCard()

                    TestTokenEnvironmentCard(environment: $viewModel.environment)

                    if hasToken {
                        TestTokenRunCard(viewModel: viewModel, model: model)
                        TestTokenResultsCard(
                            results: viewModel.results,
                            isRunning: viewModel.isRunning
                        )
                    } else {
                        TestTokenEmptyCard(environment: viewModel.environment)
                    }
                }
                .padding(.top, AppSpacing.scrollTop)
                .padding(.bottom, AppSpacing.scrollBottom)
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

// MARK: - Cards

private struct TestTokenHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Test Your Token")
                .font(.title)
                .bold()
            Text("Runs a handful of read-only API calls so you can confirm your stored token actually works end-to-end.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .glassCard()
    }
}

private struct TestTokenEnvironmentCard: View {
    @Binding var environment: LoginEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("API")
                .font(.headline)
            Picker("API", selection: $environment) {
                Text("Owners API").tag(LoginEnvironment.owner)
                Text("Fleet API").tag(LoginEnvironment.fleet)
            }
            .pickerStyle(.segmented)
        }
        .glassCard()
    }
}

private struct TestTokenRunCard: View {
    @Bindable var viewModel: TestTokenViewModel
    @Bindable var model: AuthViewModel

    var body: some View {
        Button("Run Tests", systemImage: "play.fill") {
            Task { await viewModel.run(model: model) }
        }
        .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
        .foregroundStyle(.white)
        .disabled(viewModel.isRunning)
        .accessibilityIdentifier("runTestsButton")
    }
}

private struct TestTokenResultsCard: View {
    let results: [TestAPIResult]
    let isRunning: Bool

    var body: some View {
        if isRunning {
            HStack(spacing: AppSpacing.sm) {
                ProgressView()
                Text("Running tests…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .glassCard()
        } else if !results.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Results")
                    .font(.title2)
                    .bold()
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                        TestTokenResultRow(result: result)
                        if index < results.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .glassCard()
        }
    }
}

private struct TestTokenResultRow: View {
    let result: TestAPIResult

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: result.isSuccess ? "checkmark.seal.fill" : "xmark.octagon.fill")
                    .font(.title3)
                    .foregroundStyle(result.isSuccess ? .green : Color("TeslaRed"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.headline)
                    Text(result.endpoint)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            if let summary = result.summary {
                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.leading, AppSpacing.xl - AppSpacing.xs)
            }
            if case .failure(let code) = result.status, code > 0 {
                Text("HTTP \(code)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color("TeslaRed"))
                    .padding(.leading, AppSpacing.xl - AppSpacing.xs)
            }
        }
    }
}

private struct TestTokenEmptyCard: View {
    let environment: LoginEnvironment

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "key.slash")
                .font(.largeTitle)
                .foregroundStyle(Color("TeslaRed"))
            Text("No token signed in")
                .font(.title2)
                .bold()
            Text("Sign in to the \(environment == .owner ? "Owners" : "Fleet") API tab first.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
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
