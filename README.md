# Rootlink - Modern File Manager for Linux Wayland

A premium, production-grade file manager for Sway/Arch Linux with native Wayland support. Inspired by macOS Finder and Arc Browser aesthetics.

## Features

### Core Functionality
- **Real Filesystem Integration** - Direct access to Linux filesystem
- **File Operations** - Copy, move, delete, rename, duplicate
- **Trash Support** - Safe file deletion with restore capability
- **Drag & Drop** - Full support for dragging and dropping files
- **Multi-selection** - Select multiple files with keyboard shortcuts
- **Keyboard Shortcuts** - Comprehensive keyboard navigation

### View Modes
- **Grid View** - Icon-based layout with thumbnails
- **List View** - Detailed list with file metadata
- **Column View** - Finder-like column browser

### Advanced Features
- **Quick Look** - Spacebar preview for instant file viewing
- **Search Engine** - Indexed full-text search with relevance scoring
- **Thumbnails** - Cached thumbnail generation with lazy loading
- **File Watcher** - Real-time filesystem change detection
- **Tabs** - Multi-tab browsing support
- **Split View** - Side-by-side directory browsing

### UI/UX
- **Premium Design** - macOS-inspired interface with Arc Browser aesthetics
- **Wayland Native** - No X11 dependencies, SwayFX blur support
- **GPU Acceleration** - Smooth 120fps animations
- **Theme System** - Dynamic light/dark mode support
- **Responsive Layout** - Adapts to different screen sizes

## Technology Stack

- **Frontend**: Qt6 + QML
- **Backend**: Rust with Tokio async runtime
- **File System**: Direct Linux API access
- **Display**: Native Wayland protocol
- **Search**: SQLite-based indexing
- **UI Effects**: GPU acceleration with Qt6

## Quick Start

### Build
```bash
cd /home/ravi/rootlink
./build.sh
```

### Run
```bash
./build/rootlink
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+1 | Grid view |
| Ctrl+2 | List view |
| Ctrl+3 | Column view |
| Ctrl+F | Search |
| Ctrl+C | Copy |
| Ctrl+V | Paste |
| Ctrl+H | Toggle hidden |
| Space | Quick Look |

## Project Structure

- `src/rust/` - Rust backend modules
- `src/qml/` - Qt QML UI components
- `resources/` - Assets and themes
- `Cargo.toml` - Rust dependencies
- `CMakeLists.txt` - Build configuration

## License

MIT License