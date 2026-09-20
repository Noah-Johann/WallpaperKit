// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

public func getWallpaper(screen: NSScreen) throws -> CGImage? {
    let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")
    guard let screenNumber = screen.deviceDescription[screenNumberKey] as? NSNumber else {
        throw WallpaperKitError.displayNotFound
    }

    let displayID = CGDirectDisplayID(screenNumber.uint32Value)
    guard let wallpaper = WindowInfo.wallpaperWindow(on: displayID) else {
        throw WallpaperKitError.wallpaperWindowNotFound
    }

    print("Capturing wallpaper window \(wallpaper.windowID), title=\(wallpaper.title ?? "<none>"), layer=\(wallpaper.layer)")
    let capture = SkyLightCapture.shared?.captureImage(windowID: wallpaper.windowID)
    guard capture != nil else {
        throw WallpaperKitError.captureFailed
    }
    return capture
}
