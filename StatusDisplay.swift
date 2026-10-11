import AppKit

func statusDisplay(download: String, upload: String) -> NSImage {
    let font = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium)
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]
    let width = max(58, ceil(max((download as NSString).size(withAttributes: attributes).width,
                                  (upload as NSString).size(withAttributes: attributes).width)) + 17)
    let image = NSImage(size: NSSize(width: width, height: 22), flipped: false) { rect in
        for (arrow, value, y) in [("↑", upload, CGFloat(11)), ("↓", download, CGFloat(0))] {
            (arrow as NSString).draw(at: NSPoint(x: 1, y: y), withAttributes: attributes)
            (value as NSString).draw(at: NSPoint(x: 14, y: y), withAttributes: attributes)
        }
        return true
    }
    image.isTemplate = true
    return image
}

func writePNG(_ image: NSImage, to path: String, scale: Int = 1, background: NSColor? = nil) throws {
    let size = image.size
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width) * scale,
                              pixelsHigh: Int(size.height) * scale, bitsPerSample: 8,
                              samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                              colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.cgContext.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    if let background = background {
        background.setFill()
        NSRect(origin: .zero, size: size).fill()
    }
    image.draw(in: NSRect(origin: .zero, size: size))
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}
