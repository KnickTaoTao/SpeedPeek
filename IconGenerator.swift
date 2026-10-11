import AppKit

@main
enum IconGenerator {
    static func main() throws {
        let directory = CommandLine.arguments[1]
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        for size in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
                    let w = CGFloat(size)
                    NSColor(calibratedRed: 0.05, green: 0.34, blue: 0.75, alpha: 1).setFill()
                    NSBezierPath(roundedRect: rect.insetBy(dx: w * 0.05, dy: w * 0.05), xRadius: w * 0.22, yRadius: w * 0.22).fill()
                    for (x, up) in [(CGFloat(0.34), false), (CGFloat(0.66), true)] {
                        let path = NSBezierPath()
                        let tail = w * (up ? 0.28 : 0.72)
                        let tip = w * (up ? 0.72 : 0.28)
                        let shoulder = w * (up ? 0.57 : 0.43)
                        path.move(to: NSPoint(x: w*x, y: tail)); path.line(to: NSPoint(x: w*x, y: tip))
                        path.move(to: NSPoint(x: w*(x-0.12), y: shoulder)); path.line(to: NSPoint(x: w*x, y: tip)); path.line(to: NSPoint(x: w*(x+0.12), y: shoulder))
                        path.lineWidth = w * 0.075; path.lineCapStyle = .round; path.lineJoinStyle = .round
                        (up ? NSColor.white : NSColor(calibratedRed: 0.35, green: 0.93, blue: 0.88, alpha: 1)).setStroke()
                        path.stroke()
                    }
                    return true
                }
                let suffix = scale == 2 ? "@2x" : ""
                try writePNG(image, to: directory + "/icon_\(size)x\(size)\(suffix).png", scale: scale)
            }
        }
    }
}
