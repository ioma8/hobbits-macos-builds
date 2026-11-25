#!/usr/bin/env bash
set -euo pipefail

# Hobbits macOS one-shot builder (Apple Silicon/Intel)
# - Installs Homebrew if missing
# - Installs host tools only. The CMake superbuild downloads and builds
#   Qt 6.8.3, libusb, and libpcap; do not point CMake at Homebrew Qt 5.
# - Configures and builds Hobbits
# - Installs so plugins and Qt are staged into the app bundle
# - Creates a DMG for distribution

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
INSTALL_DIR="$BUILD_DIR/install"
APP_DIR="$INSTALL_DIR/hobbits.app"
APP_BIN="$APP_DIR/Contents/MacOS/hobbits"
APP_PLUGINS="$APP_DIR/Contents/PlugIns/hobbits"
DMG_NAME="hobbits-macos.dmg"

echo "[1/6] Checking Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -d "/opt/homebrew/bin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -d "/usr/local/bin" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

echo "[2/6] Ensuring host build tools"
brew bundle --file=- <<'BREWFILE'
brew "cmake"
brew "ninja"
brew "perl"
brew "python@3.13"
brew "create-dmg"
BREWFILE

if ! command -v make >/dev/null 2>&1; then
  echo "ERROR: make is required (install Xcode Command Line Tools)" >&2
  exit 1
fi

echo "[3/6] Configure"
cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -G Ninja -DCMAKE_BUILD_TYPE=Release

echo "[4/6] Build"
# Outer parallelism is the number of dependency projects. Each one uses
# HOBBITS_DEPENDENCY_JOBS (default 4). Match upstream's CI choice.
cmake --build "$BUILD_DIR" --parallel 2

echo "[5/6] Install (stages plugins and Qt into the app bundle)"
cmake --install "$BUILD_DIR" --prefix "$INSTALL_DIR"

echo "[6/6] Verify bundle and create DMG"
if [[ ! -x "$APP_BIN" ]]; then
  echo "ERROR: App binary not found at $APP_BIN" >&2
  exit 1
fi
if [[ ! -d "$APP_DIR/Contents/Frameworks" ]]; then
  echo "ERROR: Qt frameworks were not deployed to $APP_DIR/Contents/Frameworks" >&2
  exit 1
fi
if [[ ! -d "$APP_PLUGINS" ]]; then
  echo "ERROR: Plugins directory not found at $APP_PLUGINS" >&2
  exit 1
fi
plugin_count="$(find "$APP_PLUGINS" -type f -name '*.dylib' | wc -l | tr -d ' ')"
if [[ "${plugin_count}" -eq 0 ]]; then
  echo "ERROR: No plugins staged at $APP_PLUGINS" >&2
  exit 1
fi

DMG_SRC="$BUILD_DIR/dmg-src"
DMG_OUT="$BUILD_DIR/$DMG_NAME"
rm -rf "$DMG_SRC"
mkdir -p "$DMG_SRC"
cp -R "$APP_DIR" "$DMG_SRC/"
rm -f "$DMG_OUT"
create-dmg \
  --volname "Hobbits" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 96 \
  --app-drop-link 425 200 \
  "$DMG_OUT" \
  "$DMG_SRC"

echo "Done. DMG created at: $DMG_OUT"
