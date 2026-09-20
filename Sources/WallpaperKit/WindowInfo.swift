import AppKit
import CoreGraphics

/// A WindowServer window description used to find the wallpaper compositor
/// window for a particular display.
struct WindowInfo {
    let windowID: CGWindowID
    let frame: CGRect
    let title: String?
    let applicationName: String
    let bundleIdentifier: String?
    let processID: pid_t
    let layer: Int
    let isOnScreen: Bool

    /// All currently on-screen windows, in WindowServer Z-order (front-most first).
    ///
    /// Do not exclude desktop elements here. The wallpaper is itself a desktop
    /// WindowServer window, and excluding those elements was why the demo was
    /// selecting an arbitrary application window rather than the wallpaper.
    static func enumerate() -> [WindowInfo] {
        let opts: CGWindowListOption = [.optionOnScreenOnly]
        guard let raw = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        var bundleCache: [pid_t: String?] = [:]
        return raw.compactMap { entry in
            guard let id = entry[kCGWindowNumber as String] as? UInt32,
                  let pidNum = entry[kCGWindowOwnerPID as String] as? Int32,
                  let boundsDict = entry[kCGWindowBounds as String] as? [String: Any],
                  let frame = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
            else { return nil }
            let pid = pid_t(pidNum)
            let owner = (entry[kCGWindowOwnerName as String] as? String) ?? ""
            let title = entry[kCGWindowName as String] as? String
            let layer = (entry[kCGWindowLayer as String] as? Int) ?? 0
            let onScreen = (entry[kCGWindowIsOnscreen as String] as? Bool) ?? false
            let bundleID: String?
            if let cached = bundleCache[pid] {
                bundleID = cached
            } else {
                let resolved = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
                bundleCache[pid] = resolved
                bundleID = resolved
            }
            return WindowInfo(
                windowID: CGWindowID(id),
                frame: frame,
                title: title,
                applicationName: owner,
                bundleIdentifier: bundleID,
                processID: pid,
                layer: layer,
                isOnScreen: onScreen
            )
        }
    }

    /// Finds the wallpaper window using the same observable inputs as the
    /// decompiled capture routine: display intersection, a `Wallpaper` title,
    /// and the WindowServer layer.
    static func wallpaperWindow(on displayID: CGDirectDisplayID) -> WindowInfo? {
        let displayBounds = CGDisplayBounds(displayID)
        let displayArea = max(displayBounds.width * displayBounds.height, 1)

        return enumerate()
            .compactMap { window -> (window: WindowInfo, score: CGFloat)? in
                let intersection = window.frame.intersection(displayBounds)
                guard !intersection.isNull,
                      intersection.width > 0,
                      intersection.height > 0 else {
                    return nil
                }

                // Prefer a window that covers the display, then strongly favor
                // the wallpaper-named, background-layer window when present.
                var score = (intersection.width * intersection.height) / displayArea
                if window.title?.hasPrefix("Wallpaper") == true {
                    score += 4
                }
                if window.layer < 0 {
                    score += 2
                }
                if window.applicationName == "Window Server" {
                    score += 1
                }
                return (window, score)
            }
            .max { $0.score < $1.score }?
            .window
    }
}
