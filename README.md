# Rootlink

![Platform](https://img.shields.io/badge/platform-Linux%20Wayland-1793d1?style=for-the-badge&logo=linux&logoColor=white)
![Qt](https://img.shields.io/badge/UI-Qt6%20%2B%20QML-41cd52?style=for-the-badge&logo=qt&logoColor=white)
![Rust](https://img.shields.io/badge/backend-Rust-b7410e?style=for-the-badge&logo=rust&logoColor=white)
![Build](https://img.shields.io/badge/build-CMake%20%2B%20Cargo-064f8c?style=for-the-badge&logo=cmake&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-111827?style=for-the-badge)

Rootlink is a native Linux/Wayland file manager built with Qt6/QML, C++, and Rust. It focuses on fast folder browsing, keyboard-first navigation, polished right-click actions, and real desktop clipboard support.

> A clean, Wayland-first file manager for `/home/ravi`, with a Finder-like workflow and Linux-native behavior.

## Highlights

- Native Qt6/QML interface with smooth grid, list, and preview views
- Real file operations with cross-app copy, cut, and paste support
- Thoughtful file styling for apps, dotfiles, presentations, media, code, archives, and documents
- User-installable `.desktop` launcher for app menus such as wofi and rofi
- Compact architecture that keeps the active UI path easy to inspect and extend

## Features

- Grid, list, and preview-style file views
- Sidebar shortcuts for common folders, mounted drives, system, and trash
- File operations: copy, cut, paste, rename, trash, new folder, open, open with default app, copy path, and file info
- Desktop clipboard integration for file copy/paste across other Linux file managers
- Multi-selection and keyboard shortcuts
- Empty-folder and empty-search states
- File type styling for folders, apps, dotfiles, presentations, images, audio, video, PDFs, code, archives, and text files
- Search within the current folder
- Light/dark theme structure with shared color, spacing, and typography tokens
- Wayland-first Qt application with a user-installable `.desktop` launcher

## Tech Stack

- Frontend: Qt6, QML, C++
- Backend modules: Rust, Tokio, SQLite, notify, image processing
- Build: CMake, Ninja, Cargo
- Platform: Linux Wayland

## Requirements

Arch Linux:

```bash
sudo pacman -S qt6-base qt6-declarative rust cargo cmake ninja
```

Ubuntu/Debian:

```bash
sudo apt install qt6-base-dev qt6-declarative-dev rustc cargo cmake ninja-build
```

## Build And Run

```bash
cd /home/ravi/rootlink
./build.sh
./build/rootlink
```

Install or refresh the launcher:

```bash
./install-local.sh
```

The installed desktop entry is written to:

```text
~/.local/share/applications/rootlink.desktop
```

The installed binary is:

```text
~/.local/bin/rootlink
```

To make Rootlink the default folder opener:

```bash
xdg-mime default rootlink.desktop inode/directory
```

## Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| `Ctrl+1` | Grid view |
| `Ctrl+2` | List view |
| `Ctrl+3` | Preview view |
| `Alt+Left` | Back |
| `Alt+Right` | Forward |
| `Ctrl+C` | Copy selected files |
| `Ctrl+X` | Cut selected files |
| `Ctrl+V` | Paste files |
| `Escape` | Clear selection |
| `Return` | Open selected file |

## Project Layout

```text
rootlink/
├── src/
│   ├── qml/
│   │   ├── main.qml        # Main application UI
│   │   ├── main.cpp        # Qt entry point and file-operation bridge
│   │   ├── components/     # Reusable QML components
│   │   ├── pages/          # Page-level QML views
│   │   └── theme/          # Colors, spacing, typography, theme tokens
│   └── rust/
│       ├── filesystem.rs   # Filesystem service
│       ├── filewatcher.rs  # File change watcher
│       ├── search.rs       # SQLite search engine
│       ├── thumbnails.rs   # Thumbnail generation
│       ├── qml_bridge.rs   # Rust/QML bridge experiments
│       ├── theme.rs        # Theme persistence
│       └── errors.rs       # Shared errors
├── resources/
│   ├── applications/       # Desktop file
│   ├── icons/              # App icon
│   └── config.default.json # Default preferences
├── Cargo.toml
├── CMakeLists.txt
├── build.sh
└── install-local.sh
```

## Architecture

Rootlink is organized in layers:

```text
QML UI
  -> Qt/C++ bridge exposed to QML
  -> Rust backend modules
  -> Linux filesystem, clipboard, Wayland, and storage devices
```

The current UI path is centered in `src/qml/main.qml`, with native file operations exposed from `src/qml/main.cpp`. Rust modules provide the longer-term backend structure for filesystem services, search, thumbnails, watching, configuration, and error handling.

## Development

Useful commands:

```bash
cmake --build build
cargo build --release
cargo test --release
cargo fmt
cargo clippy
RUST_LOG=debug ./build/rootlink
QT_DEBUG_PLUGINS=1 ./build/rootlink
QML_IMPORT_TRACE=1 ./build/rootlink
```

When adding features:

- Put QML UI changes near the existing component or view pattern.
- Use theme tokens from `src/qml/theme/` instead of hardcoded styling where possible.
- Add file operations through the Qt/QML bridge used by `main.qml`.
- Keep Rust backend changes async where I/O is involved.
- Rebuild with `cmake --build build` and refresh the installed launcher with `./install-local.sh` when desktop launching matters.

## Troubleshooting

- If the launcher opens an old build, run `./install-local.sh`.
- If Qt plugins fail to load, run `QT_DEBUG_PLUGINS=1 ./build/rootlink`.
- If QML imports fail, run `QML_IMPORT_TRACE=1 ./build/rootlink`.
- If file watching stops on huge trees, check `cat /proc/sys/fs/inotify/max_user_watches`.
- Existing Rust warnings are mostly from backend modules that are scaffolded but not fully wired into the active QML path yet.

## License

MIT License. See [LICENSE](LICENSE).
