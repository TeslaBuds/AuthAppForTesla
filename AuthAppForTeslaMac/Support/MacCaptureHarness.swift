#if DEBUG
import AppKit
import SwiftUI
import TeslaAuthKit

/// The Mac's own capture harness: with `enable-testing <scenario>
/// -mac-capture <name>` the app seeds the screenshot fixture (model only,
/// never the keychain), sizes its window, photographs it and quits.
/// `-mac-capture-settings <tab>` photographs the Settings window instead.
/// Screenshots/capture-mac.sh drives it; the images are the presented
/// window, not component previews.
@MainActor
enum MacCaptureHarness {
    static func argument(after flag: String) -> String? {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else { return nil }
        return args[index + 1]
    }

    static func runIfRequested(model: AuthViewModel) async {
        guard let name = argument(after: "-mac-capture") else { return }
        FileHandle.standardError.write(Data("CAPTURE START \(name)\n".utf8))
        // Past launch, the split view's first layout and the fixture's render.
        try? await Task.sleep(for: .seconds(3))
        NSApp.activate()
        let window = NSApp.windows.first { $0.isVisible && $0.canBecomeMain && $0.identifier?.rawValue.contains(MainWindow.id) == true }
            ?? NSApp.windows.first { $0.isVisible && $0.canBecomeMain }
        if let window {
            window.makeKeyAndOrderFront(nil)
            var frame = window.frame
            frame.size = CGSize(width: 1100, height: 820)
            window.setFrame(frame, display: true, animate: false)
            window.center()
        }
        try? await Task.sleep(for: .seconds(2))

        if let settingsTab = argument(after: "-mac-capture-settings") {
            NotificationCenter.default.post(name: .macCaptureOpenSettings, object: settingsTab)
            try? await Task.sleep(for: .seconds(2))
            let path = await MacWindowSnapshot.capture(named: name, titleContains: settingsTab) ?? "-"
            FileHandle.standardError.write(Data("CAPTURE \(name) \(path)\n".utf8))
        } else {
            let path = await MacWindowSnapshot.capture(named: name) ?? "-"
            FileHandle.standardError.write(Data("CAPTURE \(name) \(path)\n".utf8))
        }
        FileHandle.standardError.write(Data("CAPTURES DONE\n".utf8))
        NSApp.terminate(nil)
    }
}

extension Notification.Name {
    static let macCaptureOpenSettings = Notification.Name("MacCaptureOpenSettings")
}
#endif
