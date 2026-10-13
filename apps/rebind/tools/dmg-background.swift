// Draws the disk-image window background: a calm canvas with one arrow from the
// app icon to the Applications folder. Not part of Rebind.app.
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift tools/dmg-background.swift scripts/dmg
//
// Writes background.png, background@2x.png and the combined background.tiff that
// scripts/release.sh uses. Icon centres are at x 170 and 490, y 190 in a 660×400 window.

import AppKit

let directory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
let size = CGSize(width: 660, height: 400)

func render(scale: CGFloat) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let context = NSGraphicsContext.current!.cgContext

    // Canvas: the app's light background with a soft glow in the top-left corner.
    let colors = [NSColor(srgbRed: 0.965, green: 0.972, blue: 0.992, alpha: 1).cgColor,
                  NSColor(srgbRed: 0.925, green: 0.938, blue: 0.972, alpha: 1).cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: size.width, y: 0), options: [])

    // Arrow between the two icons, drawn like the arrows of the app icon: a thick rounded
    // stroke with the keycap's blue gradient and a soft shadow for depth.
    // (AppKit's origin is bottom-left; icons sit at y 190 from the top.)
    let y = size.height - 190
    let line = CGMutablePath()
    line.move(to: CGPoint(x: 276, y: y))
    line.addLine(to: CGPoint(x: 384, y: y))
    line.move(to: CGPoint(x: 356, y: y + 28))
    line.addLine(to: CGPoint(x: 384, y: y))
    line.addLine(to: CGPoint(x: 356, y: y - 28))
    let arrow = line.copy(strokingWithWidth: 18, lineCap: .round, lineJoin: .round, miterLimit: 10)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -6), blur: 12,
                      color: NSColor(srgbRed: 0.11, green: 0.25, blue: 0.69, alpha: 0.35).cgColor)
    context.addPath(arrow)
    context.setFillColor(NSColor(srgbRed: 0.184, green: 0.4, blue: 0.961, alpha: 1).cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(arrow)
    context.clip()
    let face = [NSColor(srgbRed: 0.435, green: 0.608, blue: 1, alpha: 1).cgColor,
                NSColor(srgbRed: 0.184, green: 0.4, blue: 0.961, alpha: 1).cgColor] as CFArray
    let faceGradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: face, locations: [0, 1])!
    context.drawLinearGradient(faceGradient, start: CGPoint(x: 0, y: y + 37), end: CGPoint(x: 0, y: y - 37), options: [])
    context.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
try render(scale: 1).write(to: directory.appendingPathComponent("background.png"))
try render(scale: 2).write(to: directory.appendingPathComponent("background@2x.png"))
print("Wrote backgrounds to \(directory.path)")
