#!/usr/bin/env bash
set -euo pipefail

# Hobbits macOS one-shot builder (Apple Silicon/Intel)
# - Installs Homebrew if missing
# - Installs deps: qt@5, cmake, libusb, pkg-config, python (for build)
# - Configures and builds Hobbits
# - Stages plugins into the app bundle default path
# - Creates a DMG for distribution

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/bin/hobbits.app"
APP_BIN="$APP_DIR/Contents/MacOS/hobbits"
APP_PLUGINS="$APP_DIR/Contents/PlugIns/hobbits"
DMG_NAME="hobbits-macos.dmg"

echo "[1/8] Checking Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -d "/opt/homebrew/bin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -d "/usr/local/bin" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

echo "[2/8] Ensuring build dependencies"
brew bundle --file=- <<'BREWFILE'
brew "cmake"
brew "pkg-config"
brew "qt@5"
brew "libusb"
brew "python@3.13"
brew "create-dmg"
BREWFILE

echo "[3/8] Environment for Qt"
export CMAKE_PREFIX_PATH="$(brew --prefix qt@5)"

echo "[4/8] Init submodules"
git submodule update --init --recursive

echo "[5/8] Configure + Build"
cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" -j

echo "[6/8] Stage plugins into app bundle"
mkdir -p "$APP_PLUGINS"
rsync -a "$BUILD_DIR/plugins/" "$APP_PLUGINS/"

echo "[7/8] Verify app binary exists"
if [[ ! -x "$APP_BIN" ]]; then
  echo "ERROR: App binary not found at $APP_BIN" >&2
  exit 1
fi

echo "[8/8] Create DMG"
DMG_OUT="$BUILD_DIR/$DMG_NAME"
rm -f "$DMG_OUT"
create-dmg \
  --volname "Hobbits" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 96 \
  --app-drop-link 425 200 \
  "$DMG_OUT" \
  "$BUILD_DIR/bin"

echo "Done. DMG created at: $DMG_OUT"
