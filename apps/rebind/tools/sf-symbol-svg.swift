// Exports SF Symbols as SVG outlines for the Sketch design system.
// Usage: xcrun swift apps/rebind/tools/sf-symbol-svg.swift <output-directory> <symbol-name>...
// SwiftUI's ImageRenderer writes symbols to PDF as plain filled paths; this converts
// those path operators to one SVG <path>. Symbols are for Rebind's own mockups only.
import AppKit
import SwiftUI

@MainActor func svg(for name: String) -> String? {
    guard NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil else { return nil }
    let renderer = ImageRenderer(content: Image(systemName: name)
        .symbolRenderingMode(.monochrome).font(.system(size: 100, weight: .medium)).foregroundStyle(.black))
    let data = NSMutableData()
    var size = CGSize.zero
    renderer.render { renderedSize, draw in
        size = renderedSize
        var box = CGRect(origin: .zero, size: renderedSize)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &box, nil) else { return }
        context.beginPDFPage(nil)
        draw(context)
        context.endPDFPage()
        context.closePDF()
    }
    guard let document = CGPDFDocument(CGDataProvider(data: data as CFData)!), let page = document.page(at: 1) else { return nil }
    final class Collector { var path = ""; var evenOdd = false; var height: CGFloat = 0 }
    let collector = Collector()
    collector.height = size.height
    func numbers(_ scanner: CGPDFScannerRef, _ count: Int) -> [CGFloat] {
        var values: [CGFloat] = []
        for _ in 0..<count {
            var value: CGPDFReal = 0
            if CGPDFScannerPopNumber(scanner, &value) { values.insert(value, at: 0) }
        }
        return values
    }
    func point(_ x: CGFloat, _ y: CGFloat, _ height: CGFloat) -> String {
        String(format: "%.2f %.2f", x, height - y)
    }
    let table = CGPDFOperatorTableCreate()!
    CGPDFOperatorTableSetCallback(table, "m") { scanner, info in
        let c = Unmanaged<Collector>.fromOpaque(info!).takeUnretainedValue()
        let n = numbers(scanner, 2)
        c.path += "M\(point(n[0], n[1], c.height))"
    }
    CGPDFOperatorTableSetCallback(table, "l") { scanner, info in
        let c = Unmanaged<Collector>.fromOpaque(info!).takeUnretainedValue()
        let n = numbers(scanner, 2)
        c.path += "L\(point(n[0], n[1], c.height))"
    }
    CGPDFOperatorTableSetCallback(table, "c") { scanner, info in
        let c = Unmanaged<Collector>.fromOpaque(info!).takeUnretainedValue()
        let n = numbers(scanner, 6)
        c.path += "C\(point(n[0], n[1], c.height)) \(point(n[2], n[3], c.height)) \(point(n[4], n[5], c.height))"
    }
    CGPDFOperatorTableSetCallback(table, "h") { _, info in
        Unmanaged<Collector>.fromOpaque(info!).takeUnretainedValue().path += "Z"
    }
    CGPDFOperatorTableSetCallback(table, "f*") { _, info in
        Unmanaged<Collector>.fromOpaque(info!).takeUnretainedValue().evenOdd = true
    }
    let stream = CGPDFContentStreamCreateWithPage(page)
    let scanner = CGPDFScannerCreate(stream, table, Unmanaged.passUnretained(collector).toOpaque())
    CGPDFScannerScan(scanner)
    CGPDFScannerRelease(scanner)
    CGPDFContentStreamRelease(stream)
    guard !collector.path.isEmpty else { return nil }
    let rule = collector.evenOdd ? " fill-rule=\"evenodd\"" : ""
    return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(Int(size.width))\" height=\"\(Int(size.height))\" viewBox=\"0 0 \(Int(size.width)) \(Int(size.height))\"><path fill=\"#000000\"\(rule) d=\"\(collector.path)\"/></svg>"
}

MainActor.assumeIsolated {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard arguments.count >= 2 else {
        print("Usage: sf-symbol-svg.swift <output-directory> <symbol-name>...")
        return
    }
    let directory = URL(fileURLWithPath: arguments[0], isDirectory: true)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for name in arguments.dropFirst() {
        guard let text = svg(for: name) else { print("MISSING \(name)"); continue }
        try? text.write(to: directory.appending(path: "\(name).svg"), atomically: true, encoding: .utf8)
    }
}
