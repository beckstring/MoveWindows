#!/bin/bash
# Assembles build/MoveWindows.app from the release binary.
# Usage: scripts/build-app.sh [codesign-identity]
#   codesign-identity defaults to "-" (ad-hoc). For a signature that survives
#   rebuilds (keeps the Accessibility grant valid), pass a self-signed
#   code-signing certificate name, e.g. "MoveWindows Dev".
set -euo pipefail

cd "$(dirname "$0")/.."

IDENTITY="${1:--}"
BUNDLE=build/MoveWindows.app

swift build -c release --product MoveWindows

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp .build/release/MoveWindows "$BUNDLE/Contents/MacOS/MoveWindows"
cp packaging/Info.plist "$BUNDLE/Contents/Info.plist"

codesign --force --sign "$IDENTITY" "$BUNDLE"

echo "Built $BUNDLE (signed: $IDENTITY)"
