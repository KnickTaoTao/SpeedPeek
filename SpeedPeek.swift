import AppKit
import SystemConfiguration
import Darwin
import ServiceManagement

// Only hardware Ethernet/Wi-Fi interfaces are counted. utun, loopback,
// bridges, AWDL and other virtual interfaces are excluded, including VPN
// payload counters already represented by bytes on the physical connection.
func physicalInterfaceNames() -> Set<String> {
    guard let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else { return [] }
    return Set(interfaces.compactMap { interface in
        guard let type = SCNetworkInterfaceGetInterfaceType(interface),
              type == kSCNetworkInterfaceTypeEthernet || type == kSCNetworkInterfaceTypeIEEE80211,
              let name = SCNetworkInterfaceGetBSDName(interface) else { return nil }
        return name as String
    })
}

func readCounters(allowed: Set<String>) -> [String: Counters] {
    var head: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&head) == 0, let first = head else { return [:] }
    defer { freeifaddrs(head) }
    var result: [String: Counters] = [:]
    var cursor: UnsafeMutablePointer<ifaddrs>? = first
    while let entry = cursor {
        defer { cursor = entry.pointee.ifa_next }
        let value = entry.pointee
        let name = String(cString: value.ifa_name)
        guard allowed.contains(name),
              (value.ifa_flags & UInt32(IFF_UP)) != 0,
              (value.ifa_flags & UInt32(IFF_RUNNING)) != 0,
              value.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
              let data = value.ifa_data?.assumingMemoryBound(to: if_data.self) else { continue }
        result[name] = Counters(received: UInt64(data.pointee.ifi_ibytes), sent: UInt64(data.pointee.ifi_obytes))
    }
    return result
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var sampler = Sampler()
    private var allowed = physicalInterfaceNames()
    private var ticks = 0
    private var sleeping = false
    private var lastTitle = ""
    private var loginItem: NSMenuItem!
    private var loginError: String?
    private var interfaceItem: NSMenuItem!
    private var startTime = ProcessInfo.processInfo.systemUptime

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.imageScaling = .scaleNone
        statusItem.button?.toolTip = "Physical network throughput • updates every 2 seconds"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "SpeedPeek — Network throughput", action: nil, keyEquivalent: ""))
        interfaceItem = NSMenuItem(title: "Interfaces: detecting…", action: nil, keyEquivalent: "")
        menu.addItem(interfaceItem)
        menu.addItem(NSMenuItem(title: "Physical bytes • VPN tunnel counters excluded", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Decimal bytes/s • includes protocol overhead", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit SpeedPeek", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
        configureLogin()
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(willSleep), name: NSWorkspace.willSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
        update()
        let poll = Timer(timeInterval: 2, repeats: true) { [weak self] _ in self?.update() }
        poll.tolerance = 0.5
        RunLoop.main.add(poll, forMode: .common)
        timer = poll
        if let index = CommandLine.arguments.firstIndex(of: "--measure-seconds"),
           CommandLine.arguments.count > index + 1,
           let duration = Double(CommandLine.arguments[index + 1]), duration > 0 {
            Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.reportResources()
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func setRates(download: String, upload: String) {
        let key = download + "\n" + upload
        guard key != lastTitle else { return }
        statusItem.button?.image = statusDisplay(download: download, upload: upload)
        statusItem.button?.setAccessibilityLabel("Download " + download + ", upload " + upload)
        statusItem.button?.toolTip = "Download: " + download + "\nUpload: " + upload + "\nUpdates every 2 seconds"
        lastTitle = key
    }

    private func configureLogin() {
        // Candidate builds never register themselves. Register only the installed application.
        guard Bundle.main.bundleURL.path == "/Applications/SpeedPeek.app" else {
            loginItem.title = "Launch at Login — available after installation"
            loginItem.isEnabled = false
            return
        }
        refreshLoginItem()
    }

    private func refreshLoginItem() {
        let status = SMAppService.mainApp.status
        loginItem.state = status == .enabled ? .on : .off
        if status == .requiresApproval {
            loginItem.title = "Launch at Login — approve in System Settings…"
        } else if let error = loginError {
            loginItem.title = "Launch at Login — retry…"
            loginItem.toolTip = error
        } else {
            loginItem.title = "Launch at Login"
            loginItem.toolTip = nil
        }
    }

    @objc private func toggleLogin() {
        loginError = nil
        if SMAppService.mainApp.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        } else {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    UserDefaults.standard.set(false, forKey: "launchAtLogin")
                } else {
                    try SMAppService.mainApp.register()
                    UserDefaults.standard.set(true, forKey: "launchAtLogin")
                }
            } catch { loginError = error.localizedDescription }
        }
        refreshLoginItem()
    }

    private func update() {
        guard !sleeping else { return }
        if ticks % 15 == 0 { allowed = physicalInterfaceNames() }
        ticks += 1
        let counters = readCounters(allowed: allowed)
        interfaceItem.title = "Interfaces: " + (counters.isEmpty ? "none active" : counters.keys.sorted().joined(separator: ", "))
        if let rates = sampler.sample(counters, at: ProcessInfo.processInfo.systemUptime) {
            setRates(download: formatMenuRate(rates.download), upload: formatMenuRate(rates.upload))
        } else {
            setRates(download: "—", upload: "—")
        }
    }

    @objc private func willSleep() {
        sleeping = true
        sampler.reset()
    }

    @objc private func didWake() {
        sleeping = false
        allowed = physicalInterfaceNames()
        sampler.reset()
        update()
    }

    @objc private func quitApp() { NSApplication.shared.terminate(nil) }

    private func reportResources() {
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        let cpu = Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec)
            + Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1_000_000
        let elapsed = ProcessInfo.processInfo.systemUptime - startTime
        print(String(format: "elapsed_seconds=%.2f cpu_seconds=%.4f average_cpu_percent=%.3f peak_rss_mib=%.2f ticks=%d",
                     elapsed, cpu, 100 * cpu / elapsed, Double(usage.ru_maxrss) / 1_048_576, ticks))
    }
}

@main
enum SpeedPeek {
    static func main() {
        if let index = CommandLine.arguments.firstIndex(of: "--render-preview"), CommandLine.arguments.count > index + 1 {
            let path = CommandLine.arguments[index + 1]
            do {
                let image = statusDisplay(download: "119K/s", upload: "148K/s")
                precondition(image.size.height == 22 && image.isTemplate)
                try writePNG(image, to: path, scale: 4, background: .white)
                print("PASS: two-row 22pt template renderer; preview written to " + path)
            } catch { fputs("Preview failed: \(error)\n", stderr); exit(1) }
            return
        }
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
