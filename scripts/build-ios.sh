#!/usr/bin/env bash
# scripts/build-ios.sh — Build the MuPDF Mobile Swift framework as an XCFramework.
#
# Output: build/ios/MuPDFMobile.xcframework
#
# Requirements:
#   • macOS with Xcode 15+
#   • swift-tools-version 5.9+
#   • MuPDF submodule initialised (git submodule update --init --recursive)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build/ios"
ARCHIVE_IOS="$BUILD_DIR/archives/iphoneos.xcarchive"
ARCHIVE_SIM="$BUILD_DIR/archives/iphonesimulator.xcarchive"
OUTPUT="$BUILD_DIR/MuPDFMobile.xcframework"

# ─── Colour output ──────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e "${GREEN}[iOS] Building MuPDF Mobile XCFramework${RESET}"

# ─── Prepare output directory ──────────────────────────────────────────────
mkdir -p "$BUILD_DIR/archives"

# ─── Build for device ───────────────────────────────────────────────────────
echo "[iOS] Archiving for iphoneos (arm64)..."
xcodebuild archive \
  -scheme MuPDFMobile \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_IOS" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | tee "$BUILD_DIR/build-iphoneos.log" | grep -E '^(Build|Archive|error:|warning:)'

# ─── Build for simulator ────────────────────────────────────────────────────
echo "[iOS] Archiving for iphonesimulator (x86_64 + arm64)..."
xcodebuild archive \
  -scheme MuPDFMobile \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$ARCHIVE_SIM" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | tee "$BUILD_DIR/build-iphonesimulator.log" | grep -E '^(Build|Archive|error:|warning:)'

# ─── Create XCFramework ─────────────────────────────────────────────────────
echo "[iOS] Creating XCFramework..."
rm -rf "$OUTPUT"
xcodebuild -create-xcframework \
  -framework "$ARCHIVE_IOS/Products/Library/Frameworks/MuPDFMobile.framework" \
  -framework "$ARCHIVE_SIM/Products/Library/Frameworks/MuPDFMobile.framework" \
  -output "$OUTPUT"

echo -e "${GREEN}[iOS] ✅  XCFramework written to: $OUTPUT${RESET}"

# ─── Swift Package Manager (dev build) ─────────────────────────────────────
echo "[iOS] Running SPM build check..."
swift build \
  --package-path "$REPO_ROOT" \
  -c release \
  2>&1 | tail -20

echo -e "${GREEN}[iOS] Done.${RESET}"
