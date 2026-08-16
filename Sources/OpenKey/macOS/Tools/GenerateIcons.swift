//
//  GenerateIcons.swift
//  LibreKey
//
//  Draws every branded asset LibreKey ships: the app icon and the menu bar
//  status icons. Assets are generated rather than hand-drawn so the logo can be
//  regenerated at any size without a binary editor.
//
//  Usage:
//      swiftc -O GenerateIcons.swift -o /tmp/genicons
//      /tmp/genicons <output-Resources-dir>
//
//  Then pack the iconset that lands next to the PNGs:
//      iconutil -c icns <output-Resources-dir>/Icon.iconset
//

import AppKit
import Foundation

// MARK: - Brand

/// LibreKey magenta. The brand mark carries a slight diagonal shift from purple
/// toward red, so keep two stops rather than one flat fill.
let brandTop = NSColor(srgbRed: 0.64, green: 0.14, blue: 0.52, alpha: 1)   // #A32385
let brandBottom = NSColor(srgbRed: 0.77, green: 0.11, blue: 0.42, alpha: 1) // #C41C6B

/// Tile behind the mark. Near-white rather than pure white so the icon still has
/// an edge on a white desktop.
let tileFace = NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1)

// MARK: - Canvas

func render(_ pixels: Int, _ height: Int? = nil, to path: String, _ body: (NSSize) -> Void) {
    let h = height ?? pixels
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                     pixelsWide: pixels, pixelsHigh: h,
                                     bitsPerSample: 8, samplesPerPixel: 4,
                                     hasAlpha: true, isPlanar: false,
                                     colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0),
          let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        FileHandle.standardError.write("cannot create bitmap for \(path)\n".data(using: .utf8)!)
        exit(1)
    }
    rep.size = NSSize(width: pixels, height: h)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    ctx.imageInterpolation = .high
    body(NSSize(width: pixels, height: h))
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else { exit(1) }
    try! data.write(to: URL(fileURLWithPath: path))
}

func glyphBounds(_ text: String, _ font: NSFont) -> CGRect {
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
    return CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
}

/// Baseline point that puts the glyph *path* dead centre in `rect`.
func baselinePoint(_ text: String, _ font: NSFont, in rect: NSRect) -> CGPoint {
    let b = glyphBounds(text, font)
    return CGPoint(x: rect.midX - b.width / 2 - b.origin.x,
                   y: rect.midY - b.height / 2 - b.origin.y)
}

/// Centres text on the geometric middle of the glyphs rather than the line box.
///
/// Drawn through CoreText on purpose. NSAttributedString.draw(at:) positions by
/// the bottom-left of the *layout box*, which sits a full descent below the
/// baseline, whereas glyph path bounds are measured *from* the baseline. Mixing
/// the two shifted every glyph up by the descent - clearly visible as a menu bar
/// letter riding above its neighbours. With CTLineDraw the text position is the
/// baseline, so both measurements share one origin.
func drawCentered(_ text: String, font: NSFont, color: NSColor, in rect: NSRect) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)

    ctx.saveGState()
    ctx.textMatrix = .identity
    ctx.textPosition = CGPoint(x: rect.midX - bounds.width / 2 - bounds.origin.x,
                               y: rect.midY - bounds.height / 2 - bounds.origin.y)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

/// Largest size at `weight` whose glyph *path* still fits inside `rect`.
///
/// Both axes are checked. Sizing on font size alone is unreliable here: cap
/// height is only about 0.7 of the point size and varies by weight, so a ratio
/// that looks right for one label overflows for the next.
func fittingFont(_ text: String, in rect: NSRect, weight: NSFont.Weight,
                 widthRatio: CGFloat = 0.90, heightRatio: CGFloat = 0.90) -> NSFont {
    let maxWidth = rect.width * widthRatio
    let maxHeight = rect.height * heightRatio
    var size = rect.height * 1.6   // deliberately too big; the loop walks it down
    while size > 4 {
        let font = NSFont.systemFont(ofSize: size, weight: weight)
        let b = glyphBounds(text, font)
        if b.width <= maxWidth && b.height <= maxHeight { return font }
        size -= 0.5
    }
    return .systemFont(ofSize: 4, weight: weight)
}

// MARK: - The mark

/// The single shape LibreKey is built from: a rounded outline with a letter inside.
/// Shared by the menu bar glyph and the app icon so the two cannot drift apart.
///
/// `rect` is the full extent of the mark, stroke included.
func drawBoxedLetter(_ text: String, in rect: NSRect, color: NSColor, strokeRatio: CGFloat) {
    let stroke = rect.height * strokeRatio

    //Inset by half the line width so the stroke lands inside `rect` rather than
    //straddling its edge and getting clipped.
    let box = rect.insetBy(dx: stroke / 2, dy: stroke / 2)
    let radius = box.width * 0.30

    color.setStroke()
    let frame = NSBezierPath(roundedRect: box, xRadius: radius, yRadius: radius)
    frame.lineWidth = stroke
    frame.stroke()

    //Breathing room between frame and letter. Measured from the box, not from the
    //stroke: tying it to stroke width couples two things that scale differently,
    //so the thinner stroke the app icon needs would shrink the padding and leave
    //the letter crammed against the frame.
    let pad = stroke / 2 + box.width * 0.14
    let inner = box.insetBy(dx: pad, dy: pad)
    drawCentered(text,
                 font: fittingFont(text, in: inner, weight: .bold,
                                   widthRatio: 1.0, heightRatio: 0.94),
                 color: color,
                 in: inner)
}

// MARK: - App icon

/// Paints the brand gradient through whatever `clip` puts on the context, so the
/// frame and the letters share one continuous ramp instead of each getting its
/// own.
func fillWithBrandGradient(in rect: NSRect, clip: (CGContext) -> Void) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    ctx.saveGState()
    clip(ctx)
    NSGradient(colors: [brandTop, brandBottom])!.draw(in: rect, angle: -45)
    ctx.restoreGState()
}

/// The LibreKey mark: a magenta rounded frame with a lowercase "lk" inside.
///
/// The frame doubles as the icon tile rather than floating inside a second one.
/// Nesting two rounded squares reads as a mark sitting on a background, and at
/// 32pt the inner one would be too small to make out.
func drawAppIcon(_ size: NSSize) {
    let s = size.width

    // macOS icon grid: content sits inset inside the canvas with a superellipse-ish
    // corner. 0.2237 of the content width is Apple's continuous-corner ratio.
    let margin = s * 0.085
    let tile = NSRect(x: margin, y: margin, width: s - 2 * margin, height: s - 2 * margin)
    let radius = tile.width * 0.2237
    let stroke = tile.width * 0.062

    tileFace.setFill()
    NSBezierPath(roundedRect: tile, xRadius: radius, yRadius: radius).fill()

    // Frame. Inset by half the line width so the stroke stays inside the tile.
    let frame = NSBezierPath(roundedRect: tile.insetBy(dx: stroke / 2, dy: stroke / 2),
                             xRadius: radius - stroke / 2, yRadius: radius - stroke / 2)
    fillWithBrandGradient(in: tile) { ctx in
        ctx.addPath(frame.cgPath)
        ctx.setLineWidth(stroke)
        ctx.replacePathWithStrokedPath()
        ctx.clip()
    }

    // "lk", light weight to match the wordmark rather than the heavy menu bar glyph.
    let inner = tile.insetBy(dx: tile.width * 0.26, dy: tile.height * 0.26)
    let font = fittingFont("lk", in: inner, weight: .light, widthRatio: 1.0, heightRatio: 1.0)
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: "lk", attributes: [.font: font]))
    fillWithBrandGradient(in: tile) { ctx in
        // .clip adds the glyph outlines to the clip path instead of painting them.
        ctx.setTextDrawingMode(.clip)
        ctx.textMatrix = .identity
        ctx.textPosition = baselinePoint("lk", font, in: inner)
        CTLineDraw(line, ctx)
    }
}

// MARK: - Menu bar

/// Menu bar glyphs are text only. At 22pt a keycap outline plus lettering turns
/// to mush.
///
/// A rounded outline with the active language inside: V while typing Vietnamese,
/// E while typing English. The box gives the glyph a defined edge so it reads as
/// a deliberate mark among the other menu bar icons instead of a stray letter.
///
/// The frame deliberately runs close to the canvas edge. Menu bar items already
/// carry their own spacing, so padding baked into the image only makes the mark
/// look small and the item unnecessarily wide.
func drawStatus(_ size: NSSize, text: String, color: NSColor) {
    //Sits a little inside the canvas rather than filling it: at full bleed the
    //mark read as larger than the system glyphs beside it.
    let rect = NSRect(origin: .zero, size: size).insetBy(dx: size.height * 0.11,
                                                         dy: size.height * 0.11)
    drawBoxedLetter(text, in: rect, color: color, strokeRatio: 0.09)
}

// MARK: - Main

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let fm = FileManager.default

// Menu bar: 22x22 @1x / 44x44 @2x. Square, because a single boxed letter is a
// square mark and any extra canvas is dead space in the menu bar.
let statusVariants: [(String, String, NSColor)] = [
    ("Status",                "V", .black),   // Vietnamese, template image
    ("StatusEng",             "E", .black),   // English, template image
    ("StatusHighlighted",     "V", .white),   // menu open, dark highlight
    ("StatusHighlightedEng",  "E", .white),
]

for (name, text, color) in statusVariants {
    render(22, 22, to: "\(out)/\(name).png") { drawStatus($0, text: text, color: color) }
    render(44, 44, to: "\(out)/\(name)@2x.png") { drawStatus($0, text: text, color: color) }
}

// App icon set
let iconset = "\(out)/Icon.iconset"
try? fm.createDirectory(atPath: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    render(base, to: "\(iconset)/icon_\(base)x\(base).png", drawAppIcon)
    render(base * 2, to: "\(iconset)/icon_\(base)x\(base)@2x.png", drawAppIcon)
}

print("wrote menu bar glyphs and \(iconset)")
