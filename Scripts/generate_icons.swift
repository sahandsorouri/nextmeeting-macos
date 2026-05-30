import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("Resources", isDirectory: true)
let iconset = resources.appendingPathComponent("AppIcon.iconset", isDirectory: true)

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

struct Color {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat
}

let transparent = Color(r: 0, g: 0, b: 0, a: 0)
let black = Color(r: 0, g: 0, b: 0, a: 1)
let white = Color(r: 1, g: 1, b: 1, a: 1)
let inkTop = Color(r: 0.08, g: 0.12, b: 0.17, a: 1)
let inkBottom = Color(r: 0.04, g: 0.07, b: 0.10, a: 1)
let teal = Color(r: 0.08, g: 0.66, b: 0.78, a: 1)
let tealDark = Color(r: 0.04, g: 0.36, b: 0.46, a: 1)
let lineGray = Color(r: 0.73, g: 0.79, b: 0.86, a: 1)
let green = Color(r: 0.18, g: 0.72, b: 0.42, a: 1)

func cg(_ color: Color) -> CGColor {
    CGColor(red: color.r, green: color.g, blue: color.b, alpha: color.a)
}

func withContext(size: Int, draw: (CGContext, CGFloat) -> Void) -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(cg(transparent))
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    draw(context, CGFloat(size))
    return context.makeImage()!
}

func savePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw NSError(domain: "NextMeetingIcon", code: 1)
    }
    CGImageDestinationAddImage(destination, image, nil)
    if !CGImageDestinationFinalize(destination) {
        throw NSError(domain: "NextMeetingIcon", code: 2)
    }
}

func roundedRect(_ context: CGContext, _ rect: CGRect, _ radius: CGFloat, _ color: Color) {
    context.setFillColor(cg(color))
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.fillPath()
}

func strokeRoundedRect(_ context: CGContext, _ rect: CGRect, _ radius: CGFloat, lineWidth: CGFloat, color: Color) {
    context.setStrokeColor(cg(color))
    context.setLineWidth(lineWidth)
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.strokePath()
}

func appIcon(size: Int) -> CGImage {
    withContext(size: size) { context, side in
        let s = side / 1024
        let bgRect = CGRect(x: 64 * s, y: 64 * s, width: 896 * s, height: 896 * s)
        let bgPath = CGPath(roundedRect: bgRect, cornerWidth: 210 * s, cornerHeight: 210 * s, transform: nil)
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [cg(inkBottom), cg(inkTop)] as CFArray,
                                  locations: [0, 1])!
        context.addPath(bgPath)
        context.clip()
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: 64 * s),
                                   end: CGPoint(x: 0, y: 960 * s),
                                   options: [])
        context.resetClip()

        roundedRect(context, CGRect(x: 214 * s, y: 184 * s, width: 596 * s, height: 660 * s), 90 * s, white)
        roundedRect(context, CGRect(x: 214 * s, y: 650 * s, width: 596 * s, height: 194 * s), 90 * s, teal)
        roundedRect(context, CGRect(x: 338 * s, y: 778 * s, width: 72 * s, height: 126 * s), 34 * s, tealDark)
        roundedRect(context, CGRect(x: 686 * s, y: 778 * s, width: 72 * s, height: 126 * s), 34 * s, tealDark)

        context.setStrokeColor(cg(lineGray))
        context.setLineWidth(28 * s)
        context.setLineCap(.round)
        for y in [540, 430] {
            context.move(to: CGPoint(x: 326 * s, y: CGFloat(y) * s))
            context.addLine(to: CGPoint(x: 646 * s, y: CGFloat(y) * s))
            context.strokePath()
        }

        context.setFillColor(cg(green))
        context.fillEllipse(in: CGRect(x: 560 * s, y: 236 * s, width: 236 * s, height: 236 * s))

        context.setFillColor(cg(white))
        context.beginPath()
        context.move(to: CGPoint(x: 648 * s, y: 300 * s))
        context.addLine(to: CGPoint(x: 648 * s, y: 408 * s))
        context.addLine(to: CGPoint(x: 732 * s, y: 354 * s))
        context.closePath()
        context.fillPath()
    }
}

func menuBarIcon(size: Int) -> CGImage {
    // Drawn on a 36-unit grid, mapped onto the pixel canvas. Generous padding +
    // thin strokes so it reads light and small next to SF Symbol menu bar items.
    withContext(size: size) { context, side in
        let s = side / 36
        context.setLineJoin(.round)
        context.setLineCap(.round)
        let lw = 1.8 * s

        // Calendar body — smaller (56% of canvas) and centered.
        strokeRoundedRect(context, CGRect(x: 8 * s, y: 7 * s, width: 20 * s, height: 20 * s),
                          4 * s, lineWidth: lw, color: black)

        // Header rule near the top of the body.
        context.setStrokeColor(cg(black))
        context.setLineWidth(1.6 * s)
        context.move(to: CGPoint(x: 10.5 * s, y: 21.5 * s))
        context.addLine(to: CGPoint(x: 25.5 * s, y: 21.5 * s))
        context.strokePath()

        // Two short binding stubs poking up above the body.
        context.setLineWidth(lw)
        for x in [14.0, 22.0] {
            context.move(to: CGPoint(x: CGFloat(x) * s, y: 27 * s))
            context.addLine(to: CGPoint(x: CGFloat(x) * s, y: 30 * s))
            context.strokePath()
        }

        // Small filled play / join triangle in the lower half.
        context.setFillColor(cg(black))
        context.beginPath()
        context.move(to: CGPoint(x: 16 * s, y: 11.5 * s))
        context.addLine(to: CGPoint(x: 16 * s, y: 17.5 * s))
        context.addLine(to: CGPoint(x: 21 * s, y: 14.5 * s))
        context.closePath()
        context.fillPath()
    }
}

let iconFiles: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in iconFiles {
    try savePNG(appIcon(size: size), to: iconset.appendingPathComponent(name))
}

try savePNG(menuBarIcon(size: 44), to: resources.appendingPathComponent("MenuBarIcon.png"))
