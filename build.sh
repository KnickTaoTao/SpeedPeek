#!/bin/zsh
set -eu
cd "${0:A:h}"
ARCH="${ARCH:-$(uname -m)}"
case "$ARCH" in arm64|x86_64) ;; *) print -u2 "Unsupported ARCH: $ARCH"; exit 1 ;; esac
TARGET="$ARCH-apple-macosx13.0"
mkdir -p SpeedPeek.app/Contents/MacOS SpeedPeek.app/Contents/Resources .build/module-cache
xcrun swiftc -O -module-cache-path "$PWD/.build/module-cache" StatusDisplay.swift IconGenerator.swift -framework AppKit -o .build/icon-generator
.build/icon-generator .build/SpeedPeek.iconset
python3 package-icon.py
xcrun swiftc -O -module-cache-path "$PWD/.build/module-cache" -target "$TARGET" Throughput.swift StatusDisplay.swift SpeedPeek.swift -framework AppKit -framework SystemConfiguration -framework ServiceManagement -o SpeedPeek.app/Contents/MacOS/SpeedPeek
cp Info.plist SpeedPeek.app/Contents/Info.plist
codesign --force --sign - SpeedPeek.app
xcrun swiftc -O -module-cache-path "$PWD/.build/module-cache" Throughput.swift Tests.swift -o .build/SpeedPeek-tests
.build/SpeedPeek-tests
SpeedPeek.app/Contents/MacOS/SpeedPeek --render-preview "$PWD/status-preview.png"
codesign --verify --deep --strict SpeedPeek.app
plutil -lint SpeedPeek.app/Contents/Info.plist
