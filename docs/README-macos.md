Hobbits on macOS (Apple Silicon)

Prerequisites
- Homebrew installed: https://brew.sh
- Xcode Command Line Tools: `xcode-select --install`

Install dependencies
- Qt 5.15: `brew install qt@5`
- libusb (optional, for USB plugin): `brew install libusb`

Environment
- For CMake to find Qt5, set:
  - zsh: `export CMAKE_PREFIX_PATH="$(brew --prefix qt@5)"`

Build
- Configure and build Release:
  - `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release`
  - `cmake --build build -j`

Run
- GUI app:
  - `open build/bin/hobbits.app`
  - or `build/bin/hobbits.app/Contents/MacOS/hobbits`
- CLI runner:
  - `build/bin/hobbits-runner --help`

Notes
- If building in new terminals often, add the `CMAKE_PREFIX_PATH` export to `~/.zshrc`.
- USB Importer plugin needs `libusb` and may require Full Disk Access for device access.
