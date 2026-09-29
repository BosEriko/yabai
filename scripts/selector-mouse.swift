import AppKit

if CommandLine.arguments.count == 8 && CommandLine.arguments[1] == "--highlight" {
    let arguments = CommandLine.arguments
    guard let width = Int(arguments[2]), let rowHeight = Int(arguments[3]),
          let radius = Double(arguments[4]), let rows = Int(arguments[5]),
          let selected = Int(arguments[6]), width > 0, rowHeight > 0,
          rows > 0, selected > 0, selected <= rows else { exit(1) }
    let height = rows * rowHeight
    guard let context = CGContext(data: nil, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: width * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
    context.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: width, height: height),
                           cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.clip()
    context.setFillColor(CGColor(red: 58 / 255, green: 58 / 255, blue: 74 / 255, alpha: 1))
    context.fill(CGRect(x: 0, y: height - selected * rowHeight, width: width, height: rowHeight))
    guard let image = context.makeImage(),
          let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { exit(1) }
    try png.write(to: URL(fileURLWithPath: arguments[7]), options: .atomic)
    exit(0)
}

final class ClickShield: NSView {
    var dismiss: (() -> Void)?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.withAlphaComponent(0.001).setFill()
        dirtyRect.fill()
    }

    override func mouseDown(with event: NSEvent) {}
    override func rightMouseDown(with event: NSEvent) {}
    override func otherMouseDown(with event: NSEvent) {}
    override func mouseUp(with event: NSEvent) { dismiss?() }
    override func rightMouseUp(with event: NSEvent) { dismiss?() }
    override func otherMouseUp(with event: NSEvent) { dismiss?() }
}

final class SelectorMouse: NSObject, NSApplicationDelegate {
    let sessionFile: String
    let session: String
    let script: String
    var panels: [NSPanel] = []
    var timer: Timer?

    init(arguments: [String]) {
        sessionFile = arguments[1]
        session = arguments[2]
        script = arguments[3]
    }

    func isCurrent() -> Bool {
        (try? String(contentsOfFile: sessionFile, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)) == session
    }

    func dismiss() {
        if isCurrent() {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = [script, "cancel", session]
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                fputs("Could not dismiss selector: \(error)\n", stderr)
            }
        }
        NSApp.terminate(nil)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard isCurrent() else { NSApp.terminate(nil); return }
        for screen in NSScreen.screens {
            let panel = NSPanel(contentRect: screen.frame,
                                styleMask: [.borderless, .nonactivatingPanel],
                                backing: .buffered, defer: false)
            panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.popUpMenuWindow)) - 1)
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.hidesOnDeactivate = false
            panel.ignoresMouseEvents = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            let shield = ClickShield(frame: NSRect(origin: .zero, size: screen.frame.size))
            shield.dismiss = { [weak self] in self?.dismiss() }
            panel.contentView = shield
            panel.orderFrontRegardless()
            panels.append(panel)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            if !self.isCurrent() { NSApp.terminate(nil) }
        }
    }
}

guard CommandLine.arguments.count == 4 else { exit(1) }
let application = NSApplication.shared
let delegate = SelectorMouse(arguments: CommandLine.arguments)
application.setActivationPolicy(.accessory)
application.delegate = delegate
application.run()
