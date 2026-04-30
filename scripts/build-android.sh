#!/usr/bin/env bash
# scripts/build-android.sh — Build the MuPDF Mobile Android AAR.
#
# Output: android/lib/build/outputs/aar/lib-release.aar
#
# Requirements:
#   • JDK 17+
#   • Android SDK with NDK r25+
#   • CMake 3.22+ (install via SDK Manager: sdk manager "cmake;3.22.1")
#   • ANDROID_HOME or ANDROID_SDK_ROOT set
#   • MuPDF submodule initialised (git submodule update --init --recursive)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$REPO_ROOT/android"
OUTPUT_AAR="$ANDROID_DIR/lib/build/outputs/aar/lib-release.aar"

# ─── Colour output ──────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${GREEN}[Android] Building MuPDF Mobile AAR${RESET}"

# ─── Java check ─────────────────────────────────────────────────────────────
if ! command -v java &>/dev/null; then
  echo "ERROR: 'java' not found. Install JDK 17+ and ensure it is on PATH." >&2
  exit 1
fi
JAVA_VER=$(java -version 2>&1 | head -1 | grep -oE '[0-9]+' | head -1)
if [ "${JAVA_VER:-0}" -lt 17 ]; then
  echo -e "${YELLOW}WARNING: Java version $JAVA_VER detected; JDK 17+ is recommended.${RESET}"
fi

# ─── local.properties ───────────────────────────────────────────────────────
LOCAL_PROPS="$ANDROID_DIR/local.properties"
if [ ! -f "$LOCAL_PROPS" ]; then
  if [ -z "${ANDROID_HOME:-}" ] && [ -z "${ANDROID_SDK_ROOT:-}" ]; then
    echo "ERROR: ANDROID_HOME / ANDROID_SDK_ROOT is not set and local.properties not found." >&2
    exit 1
  fi
  SDK_PATH="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
  echo "sdk.dir=$SDK_PATH" > "$LOCAL_PROPS"
  echo "[Android] Created local.properties with sdk.dir=$SDK_PATH"
fi

# ─── Gradle assemble ────────────────────────────────────────────────────────
echo "[Android] Running Gradle assembleRelease..."
cd "$ANDROID_DIR"
./gradlew lib:clean lib:assembleRelease --no-daemon \
  2>&1 | tee "$ANDROID_DIR/build-android.log" | \
  grep -E '^(BUILD|FAILURE|> Task|error:|warning:|> )'

if [ -f "$OUTPUT_AAR" ]; then
  echo -e "${GREEN}[Android] ✅  AAR written to: $OUTPUT_AAR${RESET}"
else
  echo "[Android] Build log: $ANDROID_DIR/build-android.log"
  echo "ERROR: Expected AAR not found at $OUTPUT_AAR" >&2
  exit 1
fi

# ─── Run unit tests ─────────────────────────────────────────────────────────
echo "[Android] Running unit tests..."
./gradlew lib:test --no-daemon 2>&1 | tail -20

echo -e "${GREEN}[Android] Done.${RESET}"
