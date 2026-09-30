#if DEBUG
import AppKit
import ScreenCaptureKit

/// Photographs one of this app's own windows, titlebar included, for the
/// screenshot and evidence runs (from RumskrotIssues #255).
///
/// `SCShareableContent.currentProcess` lists only this process's windows
/// and needs no Screen Recording permission, which neither `screencapture`
/// from an agent session nor a Mac UI test can offer on this machine.
/// `#if DEBUG`: never in a Release archive.
enum MacWindowSnapshot {
    /// Writes the largest on-screen window of this process (or the one whose
    /// title contains `titleContains`) as a PNG into the app's temporary
    /// directory and returns its path.
    static func capture(named name: String, titleContains: String? = nil) async -> String? {
        // ScreenCaptureKit refuses a capture now and then on a busy machine.
        for _ in 0..<4 {
            if let path = await attempt(named: name, titleContains: titleContains) { return path }
            try? await Task.sleep(for: .seconds(1))
        }
        return nil
    }

    private static func attempt(named name: String, titleContains: String?) async -> String? {
        do {
            let content = try await SCShareableContent.currentProcess
            var candidates = content.windows.filter { $0.isOnScreen && $0.windowLayer == 0 }
            if let titleContains {
                candidates = candidates.filter { ($0.title ?? "").localizedCaseInsensitiveContains(titleContains) }
            }
            guard let window = candidates.max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }) else {
                return nil
            }
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let configuration = SCStreamConfiguration()
            let scale = CGFloat(filter.pointPixelScale)
            configuration.width = Int(filter.contentRect.width * scale)
            configuration.height = Int(filter.contentRect.height * scale)
            configuration.showsCursor = false
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
            guard let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { return nil }
            let url = URL.temporaryDirectory.appending(path: "\(name).png")
            try data.write(to: url)
            return url.path
        } catch {
            FileHandle.standardError.write(Data("SNAPSHOT FAILED \(error)\n".utf8))
            return nil
        }
    }
}
#endif
