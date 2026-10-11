# SpeedPeek

A small native macOS menu bar network-throughput monitor. Upload is on the top row (↑), download on the bottom (↓). Built with Swift and system frameworks, without package dependencies.

[中文说明](README.zh-CN.md) · [MIT license](LICENSE) · [Sources and privacy](PROVENANCE.md)

## What it measures

Samples active hardware Ethernet and Wi-Fi interface byte counters every 2 seconds; refreshes the interface list approximately every 30 seconds and after wake. Rates use actual elapsed time and are summed across eligible interfaces. K/s, M/s and G/s mean decimal **bytes per second** (1 K = 1,000 bytes), not bits/s or binary KiB/s. Counters include traffic overhead reported by macOS, not just application payload.

Loopback, bridges, AWDL and virtual interfaces (including VPN tunnel counters) are excluded to avoid counting tunneled traffic twice. Physical VPN transport still counts. This is not per-app accounting or an Internet speed test; traffic on multiple physical links is summed. New/disappearing interfaces, counter resets and sleep gaps establish fresh baselines. First samples display a dash.

## Build and test

Requires macOS, Apple Command Line Tools providing `xcrun swiftc`, and Python 3 for icon packaging. The tested toolchain is Apple Swift 6.4 with macOS SDK 27.0. No download occurs during the build.

```sh
zsh build.sh
```

The script creates `SpeedPeek.app`, runs throughput tests, renders `status-preview.png`, checks the plist and verifies an ad-hoc code signature. Icon images are generated from source. Output is for the host architecture; use `ARCH=x86_64 zsh build.sh` to cross-compile an Intel app, or `ARCH=arm64 zsh build.sh` for Apple silicon. Each build replaces the local output app. Build commands are repeatable; byte-identical outputs across toolchains are not promised.

The app targets **macOS 13.0**, required by [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice). Compilation, unit tests and rendering passed on **Apple silicon (arm64), macOS 27.0.1**. Manual desktop testing confirmed launch, upload above download, and normal Quit behavior. Intel cross-compilation passed, but Intel execution, macOS 13 execution and login registration for this application identity have not been tested. The deployment target is not a claim of testing on every supported OS version.

## Run, login startup and uninstall

Open the locally built app. To enable login startup, install it as `/Applications/SpeedPeek.app`, launch it there, and explicitly select **Launch at Login**. This uses Apple's SMAppService; macOS may request approval in System Settings → General → Login Items. Startup is opt-in. Candidate apps outside that exact path cannot register themselves.

No administrator access, Accessibility, Screen Recording, Full Disk Access, packet capture or network extension is needed. This is a non-sandboxed menu bar app using local interface counters. It has no telemetry, update checks, network requests or persistent traffic log. Login preference is stored in the app's UserDefaults domain.

To uninstall, turn off Launch at Login, quit SpeedPeek, and remove the app. If an entry remains, remove or disable it in System Settings. Optional preference cleanup, after quitting:

```sh
defaults delete org.speedpeek.app
```

The local build is ad-hoc signed, not Developer ID signed or notarized. A downloaded binary may be blocked by Gatekeeper. This repository distributes source only; no downloadable app release is provided.

## Existing MenuMeter installations

SpeedPeek derives from the earlier MenuMeter v0.2 implementation and keeps its two-row display and sampler. It does not claim affiliation with other projects of similar names.

SpeedPeek uses bundle ID `org.speedpeek.app`, separate from the earlier app. This creates a separate preferences domain and login registration: preferences and login items are **not migrated**. Before switching, manually disable login startup in the old app and quit it; install SpeedPeek and opt in again. Both apps can otherwise appear simultaneously. No build or test script modifies the old installation or its login item.

## Source layout

- `SpeedPeek.swift`: app lifecycle, physical-interface counters and login menu.
- `Throughput.swift`, `Tests.swift`: sampling, formatting and focused tests.
- `StatusDisplay.swift`: two-row template rendering and PNG output.
- `IconGenerator.swift`, `package-icon.py`: blue dual-arrow icon generation.
- `Info.plist`, `build.sh`: app metadata and local build/test workflow.

Version 0.2, build 3. Licensed under MIT, with copyright attributed to SpeedPeek contributors. See [PROVENANCE.md](PROVENANCE.md) for source and dependency notes.

For bugs and suggestions, use [GitHub Issues](https://github.com/KnickTaoTao/SpeedPeek/issues). Do not include credentials or private logs.
