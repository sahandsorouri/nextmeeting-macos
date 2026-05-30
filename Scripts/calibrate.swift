import AppKit

// Measure the actual "ink" bounding box (non-transparent pixels) of:
//   1. the system SF Symbol "calendar" rendered as the menu bar draws it
//   2. our generated Resources/MenuBarIcon.png
// so we can size our glyph to match Apple's optical standard.

func inkBox(_ rep: NSBitmapImageRep) -> (minX: Int, minY: Int, maxX: Int, maxY: Int)? {
    var minX = rep.pixelsWide, minY = rep.pixelsHigh, maxX = -1, maxY = -1
    for y in 0..<rep.pixelsHigh {
        for x in 0..<rep.pixelsWide {
            guard let c = rep.colorAt(x: x, y: y) else { continue }
            if c.alphaComponent > 0.05 {
                if x < minX { minX = x }; if x > maxX { maxX = x }
                if y < minY { minY = y }; if y > maxY { maxY = y }
            }
        }
    }
    return maxX >= 0 ? (minX, minY, maxX, maxY) : nil
}

func report(_ name: String, _ rep: NSBitmapImageRep) {
    let canvasW = rep.pixelsWide, canvasH = rep.pixelsHigh
    if let b = inkBox(rep) {
        let w = b.maxX - b.minX + 1, h = b.maxY - b.minY + 1
        print("\(name): canvas \(canvasW)x\(canvasH)px  ink \(w)x\(h)px  height=\(String(format: "%.1f", Double(h)/Double(canvasH)*100))% of canvas")
    } else {
        print("\(name): no ink")
    }
}

// 1) SF Symbol "calendar" at 18pt regular, drawn into a 36x36 (@2x) canvas
//    centered — same way a status item draws a template image.
let pt: CGFloat = 18
let scale: CGFloat = 2
let canvas = Int(pt * scale)
let cfg = NSImage.SymbolConfiguration(pointSize: pt, weight: .regular)
if let sym = NSImage(systemSymbolName: "calendar", accessibilityDescription: nil)?
    .withSymbolConfiguration(cfg) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: canvas, pixelsHigh: canvas,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let size = sym.size
    let r = NSRect(x: (CGFloat(canvas) - size.width*scale)/2,
                   y: (CGFloat(canvas) - size.height*scale)/2,
                   width: size.width*scale, height: size.height*scale)
    sym.draw(in: r)
    NSGraphicsContext.restoreGraphicsState()
    report("SF calendar @18pt", rep)
}

// 2) Our generated menu bar icon.
let url = URL(fileURLWithPath: "Resources/MenuBarIcon.png")
if let data = try? Data(contentsOf: url), let rep = NSBitmapImageRep(data: data) {
    report("MenuBarIcon.png", rep)
}
