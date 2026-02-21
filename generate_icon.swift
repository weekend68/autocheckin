#!/usr/bin/env swift

// generate_icon.swift
// Run with: swift generate_icon.swift
// Generates the WiFiMonitor app icon using SF Symbol "person.wave.2"
// on a blue rounded-rect background, exported at all macOS icon sizes.

import AppKit
import Foundation

let blue = NSColor(red: 26 / 255.0, green: 115 / 255.0, blue: 232 / 255.0, alpha: 1)

struct IconSize {
    let points: Int
    let scale: Int
    var pixels: Int { points * scale }
    var filename: String {
        scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@\(scale)x.png"
    }
}

let sizes = [
    IconSize(points: 16, scale: 1),
    IconSize(points: 16, scale: 2),
    IconSize(points: 32, scale: 1),
    IconSize(points: 32, scale: 2),
    IconSize(points: 128, scale: 1),
    IconSize(points: 128, scale: 2),
    IconSize(points: 256, scale: 1),
    IconSize(points: 256, scale: 2),
    IconSize(points: 512, scale: 1),
    IconSize(points: 512, scale: 2),
]

let scriptPath = CommandLine.arguments[0]
let projectDir = URL(fileURLWithPath: scriptPath).deletingLastPathComponent()
let outputDir = projectDir.appendingPathComponent("WiFiMonitor/Assets.xcassets/AppIcon.appiconset")

func renderIcon(pixels: Int) -> Data? {
    let size = CGFloat(pixels)

    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
    NSGraphicsContext.current = ctx

    // Rounded rect background
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.2237
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    blue.setFill()
    path.fill()

    // White SF Symbol centred with padding
    let config = NSImage.SymbolConfiguration(paletteColors: [.white])
    if let symbol = NSImage(systemSymbolName: "person.wave.2", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let padding = size * 0.18
        let drawRect = CGRect(
            x: padding,
            y: padding,
            width: size - padding * 2,
            height: size - padding * 2
        )
        symbol.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

// Create output directory
try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

var imageEntries: [(filename: String, points: Int, scale: Int)] = []

for s in sizes {
    print("Generating \(s.pixels)×\(s.pixels)px (\(s.points)pt @\(s.scale)x)…")
    if let data = renderIcon(pixels: s.pixels) {
        let url = outputDir.appendingPathComponent(s.filename)
        try? data.write(to: url)
        print("  ✅ \(s.filename)")
        imageEntries.append((s.filename, s.points, s.scale))
    } else {
        print("  ❌ Failed to render")
    }
}

// Update Contents.json
let imagesJSON = imageEntries.map { e in
    """
        {
          "filename" : "\(e.filename)",
          "idiom" : "mac",
          "scale" : "\(e.scale)x",
          "size" : "\(e.points)x\(e.points)"
        }
    """
}.joined(separator: ",\n")

let contentsJSON = """
{
  "images" : [
\(imagesJSON)
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

let contentsURL = outputDir.appendingPathComponent("Contents.json")
try? contentsJSON.write(to: contentsURL, atomically: true, encoding: .utf8)
print("✅ Updated Contents.json")
print("Done! Open Xcode and rebuild to see the new icon.")
