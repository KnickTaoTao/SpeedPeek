import Foundation

struct Counters: Equatable {
    let received: UInt64
    let sent: UInt64
}

struct Rates: Equatable {
    let download: Double
    let upload: Double
}

struct Sampler {
    private var previous: [String: Counters] = [:]
    private var previousTime: Double?

    mutating func reset() {
        previous = [:]
        previousTime = nil
    }

    mutating func sample(_ current: [String: Counters], at time: Double) -> Rates? {
        defer { previous = current; previousTime = time }
        guard let lastTime = previousTime else { return nil }
        let elapsed = time - lastTime
        // Long gaps (sleep or a stalled run loop) establish a new baseline.
        guard elapsed > 0, elapsed <= 10 else { return nil }
        var received: Double = 0
        var sent: Double = 0
        for (name, now) in current {
            guard let before = previous[name],
                  now.received >= before.received, now.sent >= before.sent else { continue }
            received += Double(now.received - before.received)
            sent += Double(now.sent - before.sent)
        }
        return Rates(download: received / elapsed, upload: sent / elapsed)
    }
}

func formatRate(_ bytes: Double) -> String {
    if bytes >= 1_000_000_000 { return String(format: "%.1f GB/s", bytes / 1_000_000_000) }
    if bytes >= 1_000_000 { return String(format: "%.1f MB/s", bytes / 1_000_000) }
    if bytes >= 1_000 { return String(format: "%.0f kB/s", bytes / 1_000) }
    return String(format: "%.0f B/s", bytes)
}

// Compact menu-bar units; decimal bytes per second, matching the reference layout.
func formatMenuRate(_ bytes: Double) -> String {
    if bytes >= 1_000_000_000 { return String(format: "%.1fG/s", bytes / 1_000_000_000) }
    if bytes >= 1_000_000 { return String(format: "%.1fM/s", bytes / 1_000_000) }
    if bytes >= 1_000 { return String(format: "%.0fK/s", bytes / 1_000) }
    return String(format: "%.0fB/s", bytes)
}
