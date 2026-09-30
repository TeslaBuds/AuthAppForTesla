//
//  MainWindow.swift
//  AuthAppForTeslaMac
//
//  The Mac window: a sidebar with the iPhone's four tabs (Owners API,
//  Fleet API, Tools, About) and the same screens beside it. ⌘1–⌘4 and
//  the Tokens menu act on it through the focused-scene selection, exactly
//  as they act on the iPhone's tabs.
//

import SwiftUI
import TeslaAuthKit

struct MainWindow: View {
    static let id = "main"

    @Bindable var model: AuthViewModel
    @State private var selection: AppTab
    @State private var toolsPath: NavigationPath
    @State private var showOnboarding = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.openSettings) private var openSettings

    init(model: AuthViewModel, initialTab: AppTab = .owners) {
        self.model = model
        _selection = State(initialValue: initialTab)
        _toolsPath = State(initialValue: MainWindow.initialToolsPath())
    }

    var body: some View {
        NavigationSplitView {
            MainSidebar(selection: $selection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } detail: {
            MainDetail(model: model, selection: selection, toolsPath: $toolsPath)
                .safeAreaInset(edge: .top, spacing: 0) {
                    if let problem = model.storeProblem {
                        StoreProblemBanner(problem: problem)
                    }
                }
        }
        .frame(minWidth: 760, minHeight: 560)
        .tint(Color("TeslaRed"))
        .focusedSceneValue(\.selectedTab, $selection)
        .toast($model.toast)
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .frame(width: 520, height: 560)
                .onDisappear { hasSeenOnboarding = true }
        }
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: .macCaptureOpenSettings)) { _ in
            openSettings()
        }
        #endif
        .task {
            #if DEBUG
            if ScreenshotScenario.isActive { return }
            #endif
            if MacLaunch.isRunningTests { return }
            if !hasSeenOnboarding { showOnboarding = true }
        }
    }

    /// Lands the Tools column on the sub-screen a screenshot scenario wants.
    private static func initialToolsPath() -> NavigationPath {
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
}

/// The four sections, in the iPhone's tab order.
struct MainSidebar: View {
    @Binding var selection: AppTab

    var body: some View {
        List(selection: Binding<AppTab?>(get: { selection }, set: { if let new = $0 { selection = new } })) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Label(tab.title, systemImage: tab.systemImage)
                    .tag(tab)
            }
        }
        .navigationTitle("Auth for Tesla")
    }
}

/// The selected section's screen, each with its own navigation stack so a
/// pushed Tools screen never covers another section (#42).
struct MainDetail: View {
    @Bindable var model: AuthViewModel
    let selection: AppTab
    @Binding var toolsPath: NavigationPath

    var body: some View {
        switch selection {
        case .owners:
            NavigationStack {
                OwnersAPIView(model: model)
                    .navigationTitle("Owners API")
            }
        case .fleet:
            NavigationStack {
                FleetAPIView(model: model)
                    .navigationTitle("Fleet API")
            }
        case .tools:
            NavigationStack(path: $toolsPath) {
                ToolsView(model: model)
                    .navigationDestination(for: ToolsDestination.self) { destination in
                        switch destination {
                        case .jwtInspector:
                            JWTInspectorView(model: model, initialInput: MainDetail.jwtInspectorInitialInput())
                        case .snippetExporter:
                            SnippetExporterView(model: model)
                        case .testToken:
                            TestTokenView(model: model)
                        }
                    }
            }
        case .about:
            NavigationStack {
                AboutView()
                    .navigationTitle("About")
            }
        }
    }

    private static func jwtInspectorInitialInput() -> String {
        #if DEBUG
        if ScreenshotScenario.current == .jwtInspector {
            return ScreenshotHarness.currentOwnersToken
        }
        #endif
        return ""
    }
}
