//
//  RootView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI
import TeslaAuthKit

#Preview("Owners API") {
    RootView(model: AuthViewModel(), initialTab: .owners)
}

#Preview("Fleet API") {
    RootView(model: AuthViewModel(), initialTab: .fleet)
}

#Preview("About") {
    RootView(model: AuthViewModel(), initialTab: .about)
}

struct RootView: View {
    @Bindable var model: AuthViewModel
    @State private var selection: AppTab
    /// Each tab owns its own navigation stack, so a screen pushed in one
    /// section (for example Tools → Test Token) never covers another
    /// section. A single stack wrapped around the whole TabView made the
    /// About tab look unresponsive on Mac and iPad while a Tools screen was
    /// pushed on top of it (#42).
    @State private var toolsPath: NavigationPath
    @State private var showOnboarding = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    init(model: AuthViewModel, initialTab: AppTab = .owners) {
        self.model = model
        _selection = State(initialValue: initialTab)
        _toolsPath = State(initialValue: ToolsRouting.initialPath())
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab(AppTab.owners.title, systemImage: AppTab.owners.systemImage, value: .owners) {
                NavigationStack {
                    OwnersAPIView(model: model)
                }
                .toast($model.toast)
            }
            Tab(AppTab.fleet.title, systemImage: AppTab.fleet.systemImage, value: .fleet) {
                NavigationStack {
                    FleetAPIView(model: model)
                }
                .toast($model.toast)
            }
            Tab(AppTab.tools.title, systemImage: AppTab.tools.systemImage, value: .tools) {
                ToolsStack(model: model, path: $toolsPath)
                    .toast($model.toast)
            }
            Tab(AppTab.about.title, systemImage: AppTab.about.systemImage, value: .about) {
                NavigationStack {
                    AboutView()
                }
                .toast($model.toast)
            }
        }
        .tint(Color("TeslaRed"))
        // Lets the Mac menu bar's ⌘1–⌘4 and copy commands act on the
        // frontmost window's tab.
        .focusedSceneValue(\.selectedTab, $selection)
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
        // The toast is attached inside each tab, above, so it sits in the
        // tab content's safe area and clears the tab bar wherever the
        // system puts it — beside the content on the iPhone Duo (#66).
        // Back in the foreground: show what a Shortcut or the widget did
        // to the tokens meanwhile (#52).
        .onChange(of: scenePhase) { old, phase in
            if old == .background && phase != .background {
                Task { await model.reloadFromStore() }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .onDisappear {
                    hasSeenOnboarding = true
                }
        }
        .task {
            #if DEBUG
            if ScreenshotScenario.current == .onboarding {
                showOnboarding = true
                return
            }
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
            model.refreshAll(.launch)
        }
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
