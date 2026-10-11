import Foundation

@main
enum Tests {
    static func main() {
        var sampler = Sampler()
        func c(_ received: UInt64, _ sent: UInt64) -> Counters { Counters(received: received, sent: sent) }
        precondition(sampler.sample(["en0": c(100, 50)], at: 0) == nil)
        precondition(sampler.sample(["en0": c(2100, 1050)], at: 2) == Rates(download: 1000, upload: 500))
        precondition(sampler.sample(["en0": c(10, 5)], at: 4) == Rates(download: 0, upload: 0))
        precondition(sampler.sample(["en0": c(30, 15), "en1": c(999, 999)], at: 6) == Rates(download: 10, upload: 5))
        precondition(sampler.sample(["en0": c(50, 25), "en1": c(1019, 1009)], at: 8) == Rates(download: 20, upload: 10))
        precondition(sampler.sample(["en0": c(1000, 500)], at: 100) == nil)
        sampler.reset()
        precondition(sampler.sample(["en0": c(2000, 1000)], at: 102) == nil)
        precondition(sampler.sample([:], at: 104) == Rates(download: 0, upload: 0))
        precondition(sampler.sample(["en0": c(3000, 1500)], at: 106) == Rates(download: 0, upload: 0))
        precondition(formatRate(1000) == "1 kB/s")
        precondition(formatRate(1_500_000) == "1.5 MB/s")
        precondition(formatMenuRate(148_000) == "148K/s")
        precondition(formatMenuRate(119_000) == "119K/s")
        precondition(formatMenuRate(1_500_000) == "1.5M/s")
        precondition(formatMenuRate(0) == "0B/s")
        precondition(formatMenuRate(1_000_000_000) == "1.0G/s")
        print("PASS: baseline, elapsed rates, counter reset, interface addition/removal, multiple physical interfaces, sleep gap, explicit reset, decimal formatting")
    }
}
