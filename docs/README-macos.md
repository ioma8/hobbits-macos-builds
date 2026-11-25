Hobbits on macOS (Apple Silicon and Intel)

The default CMake superbuild downloads and builds Qt 6.8.3, libusb, and
libpcap. No Homebrew Qt or libusb is required. The first build compiles Qt
and takes a while. Dependencies stay inside the build directory.

Prerequisites
- Homebrew installed: https://brew.sh
- Xcode Command Line Tools: `xcode-select --install`
- CMake 3.24+, Ninja, Make, and Perl

Host tools
- `brew install cmake ninja perl python@3.13`
- Python is optional. When a Python 3.8+ interpreter and matching headers are
  found, the Python Runner and Kaitai Struct plugins are built. On macOS the
  Python standard library is not bundled into the app.

Build
- Configure and build Release:
  - `cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release`
  - `cmake --build build --parallel 2`
- Install a self-contained app (plugins and Qt are staged into the bundle):
  - `cmake --install build --prefix "$PWD/build/install"`

Run
- Build tree GUI:
  - `open build/bin/hobbits.app`
  - or `build/bin/hobbits.app/Contents/MacOS/hobbits`
- Build tree CLI:
  - `build/bin/hobbits-runner --help`
- Installed app:
  - `open build/install/hobbits.app`
  - CLI: `build/install/hobbits.app/Contents/MacOS/hobbits-runner --help`

Notes
- A one-shot build and DMG are available via `scripts/build_macos.sh`.
- USB device access may require Full Disk Access. libusb is built by the
  superbuild and installed into `hobbits.app/Contents/Frameworks`.
- To use an already installed Qt 6.8+, configure with `-DHOBBITS_USE_SYSTEM_QT=ON`
  and set `CMAKE_PREFIX_PATH` to that Qt. Homebrew `qt@5` is not compatible.
