import AppKit
import CoreGraphics
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first ?? "dist/AppIcon-1024.png"
let size = 1024
let rect = CGRect(x: 0, y: 0, width: size, height: size)

guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Could not create icon context")
}

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    let r = CGFloat((hex >> 16) & 0xFF) / 255
    let g = CGFloat((hex >> 8) & 0xFF) / 255
    let b = CGFloat(hex & 0xFF) / 255
    return CGColor(red: r, green: g, blue: b, alpha: alpha)
}

func rounded(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func fill(_ path: CGPath, _ fill: CGColor) {
    context.addPath(path)
    context.setFillColor(fill)
    context.fillPath()
}

func stroke(_ path: CGPath, _ stroke: CGColor, width: CGFloat) {
    context.addPath(path)
    context.setStrokeColor(stroke)
    context.setLineWidth(width)
    context.setLineJoin(.round)
    context.setLineCap(.round)
    context.strokePath()
}

func polygon(_ points: [CGPoint]) -> CGPath {
    let path = CGMutablePath()
    guard let first = points.first else { return path }
    path.move(to: first)
    for point in points.dropFirst() { path.addLine(to: point) }
    path.closeSubpath()
    return path
}

context.clear(rect)

// Rounded-square body.
let bodyRect = CGRect(x: 60, y: 60, width: 904, height: 904)
let body = rounded(bodyRect, radius: 205)
context.saveGState()
context.addPath(body)
context.clip()

let bgGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [color(0x17365E), color(0x07111F)] as CFArray,
    locations: [0, 1]
)!
context.drawLinearGradient(
    bgGradient,
    start: CGPoint(x: 240, y: 930),
    end: CGPoint(x: 760, y: 100),
    options: []
)

// Subtle inner glow.
context.setFillColor(color(0x2E6AA6, alpha: 0.18))
context.fillEllipse(in: CGRect(x: 90, y: 410, width: 560, height: 560))
context.restoreGState()

stroke(body, color(0x06101C), width: 18)
stroke(rounded(bodyRect.insetBy(dx: 18, dy: 18), radius: 185), color(0x5D86B0, alpha: 0.28), width: 5)

// Anvil.
let anvilTop = polygon([
    CGPoint(x: 140, y: 405), CGPoint(x: 845, y: 405),
    CGPoint(x: 790, y: 355), CGPoint(x: 252, y: 355)
])
fill(anvilTop, color(0x384451))
stroke(anvilTop, color(0x081019), width: 18)

let anvilBody = polygon([
    CGPoint(x: 250, y: 360), CGPoint(x: 782, y: 360),
    CGPoint(x: 705, y: 250), CGPoint(x: 655, y: 230),
    CGPoint(x: 642, y: 165), CGPoint(x: 380, y: 165),
    CGPoint(x: 365, y: 230), CGPoint(x: 315, y: 250)
])
fill(anvilBody, color(0x242D37))
stroke(anvilBody, color(0x07101A), width: 18)

let base = polygon([
    CGPoint(x: 335, y: 170), CGPoint(x: 692, y: 170),
    CGPoint(x: 735, y: 125), CGPoint(x: 290, y: 125)
])
fill(base, color(0x1A222C))
stroke(base, color(0x07101A), width: 18)

// Photo card frame.
let cardRect = CGRect(x: 302, y: 424, width: 410, height: 315)
let card = rounded(cardRect, radius: 48)
fill(card, color(0xF6EBD3))
stroke(card, color(0xFFF7E7), width: 14)

let inner = rounded(cardRect.insetBy(dx: 24, dy: 24), radius: 30)
context.saveGState()
context.addPath(inner)
context.clip()

let skyGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [color(0x3581C6), color(0xF2A45B)] as CFArray,
    locations: [0, 1]
)!
context.drawLinearGradient(
    skyGradient,
    start: CGPoint(x: 510, y: 700),
    end: CGPoint(x: 510, y: 455),
    options: []
)

context.setFillColor(color(0xFFD45F))
context.fillEllipse(in: CGRect(x: 565, y: 590, width: 78, height: 78))

fill(polygon([
    CGPoint(x: 325, y: 470), CGPoint(x: 455, y: 620),
    CGPoint(x: 545, y: 505)
]), color(0x17365E))
fill(polygon([
    CGPoint(x: 430, y: 470), CGPoint(x: 565, y: 575),
    CGPoint(x: 690, y: 470)
]), color(0x102544))
context.restoreGState()

// Hot forged edge.
context.setShadow(offset: .zero, blur: 26, color: color(0xFF9E32, alpha: 0.95))
stroke(rounded(cardRect.insetBy(dx: 7, dy: 7), radius: 42), color(0xFFBE55, alpha: 0.85), width: 10)
context.setShadow(offset: .zero, blur: 0)

// Hammer, rotated into the strike.
context.saveGState()
context.translateBy(x: 715, y: 760)
context.rotate(by: -0.55)

let handle = rounded(CGRect(x: -16, y: -220, width: 54, height: 310), radius: 20)
fill(handle, color(0x9D5A28))
stroke(handle, color(0x4C2A17), width: 10)

let head = rounded(CGRect(x: -105, y: 55, width: 225, height: 112), radius: 24)
fill(head, color(0x444B55))
stroke(head, color(0x0A1118), width: 15)
stroke(rounded(CGRect(x: -90, y: 70, width: 195, height: 82), radius: 18), color(0x90A1B2, alpha: 0.45), width: 5)
context.restoreGState()

// Sparks.
let sparks: [(CGPoint, CGPoint, CGFloat)] = [
    (CGPoint(x: 690, y: 710), CGPoint(x: 760, y: 770), 11),
    (CGPoint(x: 680, y: 700), CGPoint(x: 815, y: 720), 9),
    (CGPoint(x: 672, y: 695), CGPoint(x: 735, y: 835), 9),
    (CGPoint(x: 665, y: 690), CGPoint(x: 610, y: 815), 8),
    (CGPoint(x: 660, y: 684), CGPoint(x: 565, y: 758), 7)
]
context.setShadow(offset: .zero, blur: 16, color: color(0xFF9B2F, alpha: 0.9))
for (start, end, width) in sparks {
    let path = CGMutablePath()
    path.move(to: start)
    path.addLine(to: end)
    stroke(path, color(0xFFD568), width: width)
}
for point in [
    CGPoint(x: 803, y: 665), CGPoint(x: 760, y: 820),
    CGPoint(x: 590, y: 790), CGPoint(x: 842, y: 750)
] {
    context.setFillColor(color(0xFFF1A0))
    context.fillEllipse(in: CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16))
}
context.setShadow(offset: .zero, blur: 0)

guard let cgImage = context.makeImage() else {
    fatalError("Could not render icon")
}
let bitmap = NSBitmapImageRep(cgImage: cgImage)
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode icon PNG")
}

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try png.write(to: outputURL, options: .atomic)
print("Rendered \(outputPath)")
