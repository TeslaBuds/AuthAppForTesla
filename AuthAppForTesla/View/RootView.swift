//
//  RootView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI

/// Animatable font size modifier using the modern @Animatable macro.
@Animatable
struct AnimatableCustomFontModifier: ViewModifier {
    var size: Double

    func body(content: Content) -> some View {
        content
            .font(.system(size: size))
    }
}

#Preview("Owners API") {
    RootView(model: AuthViewModel(), initialTab: .owners)
}

#Preview("Fleet API") {
    RootView(model: AuthViewModel(), initialTab: .fleet)
}

#Preview("About") {
    RootView(model: AuthViewModel(), initialTab: .about)
}

extension View {
    func animatableFont(size: Double) -> some View {
        modifier(AnimatableCustomFontModifier(size: size))
    }
}

/// Tab selection backed by an enum for type safety.
enum AppTab: Hashable {
    case owners
    case fleet
    case tools
    case about
}

struct RootView: View {
    @Bindable var model: AuthViewModel
    @State private var selection: AppTab
    @State private var navigationPath: NavigationPath
    @State private var showOnboarding = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    init(model: AuthViewModel, initialTab: AppTab = .owners) {
        self.model = model
        _selection = State(initialValue: initialTab)
        _navigationPath = State(initialValue: Self.initialNavigationPath())
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            TabView(selection: $selection) {
                Tab("Owners API", systemImage: "steeringwheel", value: .owners) {
                    OwnersAPIView(model: model)
                }
                Tab("Fleet API", systemImage: "car.2.fill", value: .fleet) {
                    FleetAPIView(model: model)
                }
                Tab("Tools", systemImage: "wrench.and.screwdriver", value: .tools) {
                    ToolsView(model: model)
                }
                Tab("About", systemImage: "info.circle", value: .about) {
                    AboutView()
                }
            }
            .tint(Color("TeslaRed"))
            .navigationDestination(for: ToolsDestination.self) { destination in
                switch destination {
                case .jwtInspector:
                    JWTInspectorView(model: model, initialInput: Self.jwtInspectorInitialInput())
                case .snippetExporter:
                    SnippetExporterView(model: model)
                case .testToken:
                    TestTokenView(model: model)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            #if DEBUG
            // Hidden mirror of LiveTestLog for the live UI test. The
            // test reads `.label` on this Text via the accessibility
            // identifier and attaches it to the test result bundle.
            // The view is sized 1x1 and almost transparent so it
            // doesn't affect screenshots.
            if LiveTestLog.isActive {
                LiveTestLogReader()
            }
            #endif
        }
        .toast($model.toast)
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .onDisappear {
                    hasSeenOnboarding = true
                }
        }
        .task {
            #if DEBUG
            guard !CommandLine.arguments.contains("enable-testing") else { return }
            // Live UI tests pre-set hasSeenOnboarding=true in App.init,
            // so we don't need to do anything here for them.
            if CommandLine.arguments.contains("live-test-clear-state") {
                return
            }
            #endif
            if !hasSeenOnboarding {
                showOnboarding = true
            }
            model.refreshAll()
        }
    }

    /// Builds the initial NavigationPath for screenshot scenarios that
    /// want to land on a specific Tools sub-screen.
    private static func initialNavigationPath() -> NavigationPath {
        var path = NavigationPath()
        #if DEBUG
        switch ScreenshotScenario.current {
        case .jwtInspector: path.append(ToolsDestination.jwtInspector)
        case .snippetExporter: path.append(ToolsDestination.snippetExporter)
        case .testToken: path.append(ToolsDestination.testToken)
        default: break
        }
        #endif
        return path
    }

    /// Pre-fills the JWT inspector with the sample token only when the
    /// matching screenshot scenario is active.
    private static func jwtInspectorInitialInput() -> String {
        #if DEBUG
        if ScreenshotScenario.current == .jwtInspector {
            return ScreenshotHarness.sampleOwnersToken
        }
        #endif
        return ""
    }
}

#if DEBUG
/// Hidden Text view that mirrors LiveTestLog content into the
/// accessibility tree so the live UI test can read it after the OAuth
/// flow finishes. Observing LiveTestLog forces SwiftUI to refresh the
/// label whenever the app appends a new line.
private struct LiveTestLogReader: View {
    @State private var log = LiveTestLog.shared

    var body: some View {
        Text(log.joined.isEmpty ? "(empty)" : log.joined)
            .font(.system(size: 1))
            .foregroundStyle(.clear)
            .frame(width: 1, height: 1)
            .accessibilityIdentifier("liveTestLog")
            .accessibilityLabel(log.joined.isEmpty ? "(empty)" : log.joined)
            .allowsHitTesting(false)
    }
}
#endif
