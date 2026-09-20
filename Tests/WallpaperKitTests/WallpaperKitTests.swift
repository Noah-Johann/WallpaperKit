import Testing
import AppKit
import ImageIO
import UniformTypeIdentifiers
@testable import WallpaperKit

@Test func getWallpaperForMainScreen() async throws {
    guard let screen = NSScreen.main else {
        return
    }

    let image = try getWallpaper(screen: screen)

    #expect(image != nil)

    guard let image else {
        return
    }

    let packageDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    let outputURL = packageDirectory
        .appendingPathComponent("wallpaper-test.png")

    guard let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw NSError(
            domain: "WallpaperKitTests",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Could not create PNG image destination"
            ]
        )
    }

    CGImageDestinationAddImage(destination, image, nil)

    guard CGImageDestinationFinalize(destination) else {
        throw NSError(
            domain: "WallpaperKitTests",
            code: 2,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Could not write wallpaper-test.png"
            ]
        )
    }
}
