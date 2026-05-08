# Quick Reference Guide

## 🚀 30-SECOND STARTUP

```bash
cd /home/ravi/rootlink
./build.sh
./build/rootlink
```

## 📁 FILE LOCATIONS

- **Rust Backend**: `src/rust/`
- **QML Frontend**: `src/qml/`
- **Config**: `~/.config/rootlink/`
- **Cache**: `~/.cache/rootlink/`

## 🔧 KEY MODULES

### Rust Backend
| File | Purpose |
|------|---------|
| `main.rs` | Entry point, service init |
| `filesystem.rs` | File operations |
| `search.rs` | Search engine |
| `filewatcher.rs` | Change detection |
| `thumbnails.rs` | Thumbnail generation |
| `qml_bridge.rs` | Rust/Qt communication |
| `theme.rs` | Theme management |

### QML Frontend
| Component | Purpose |
|-----------|---------|
| `Sidebar.qml` | Left navigation |
| `Toolbar.qml` | Top controls |
| `FileGrid.qml` | Icon view |
| `FileListView.qml` | List view |
| `ColumnView.qml` | Column browser |

## ⌨️ KEYBOARD SHORTCUTS

| Shortcut | Action |
|----------|--------|
| Ctrl+1 | Grid view |
| Ctrl+2 | List view |
| Ctrl+3 | Column view |
| Ctrl+F | Search |
| Ctrl+C | Copy |
| Ctrl+V | Paste |
| Space | Quick Look |
| Escape | Clear selection |

## 🛠️ DEVELOPMENT COMMANDS

```bash
# Build Rust backend only
cargo build --release

# Build QML frontend only
cmake --build build

# Full build
./build.sh

# Debug mode
RUST_LOG=debug ./build/rootlink

# Run tests
cargo test --release

# Format code
cargo fmt

# Lint code
cargo clippy
```

## 📊 DATA FLOW

1. **User Action** (Click) 
   → QML Handler
   → Rust Backend
   → Filesystem/Database
   → Return JSON
   → Update UI

2. **File Change** (External)
   → FileWatcher
   → Broadcast Event
   → Invalidate Cache
   → Refresh UI

3. **Search**
   → User Types
   → Debounce (300ms)
   → Query SQLite
   → Display Results

## 🎨 THEME COLORS

### Dark Theme
- Background: `#1E1E1E`
- Foreground: `#2A2A2A`
- Accent: `#0A84FF`
- Text Primary: `#FFFFFF`
- Text Secondary: `#999999`

### Light Theme
- Background: `#FFFFFF`
- Foreground: `#F5F5F5`
- Accent: `#0071E3`
- Text Primary: `#000000`
- Text Secondary: `#666666`

## 🔍 COMMON TASKS

### Add New File Operation
1. Add function to `filesystem.rs`
2. Expose in `qml_bridge.rs`
3. Add UI in QML component
4. Add keyboard shortcut

### Add New View Mode
1. Create component in `src/qml/components/`
2. Add to `FileBrowser.qml`
3. Add toolbar button
4. Add keyboard shortcut

### Add New Search Filter
1. Modify query in `search.rs`
2. Add UI controls in `SearchBar.qml`
3. Pass filter parameters

## 📚 IMPORTANT FILES

```
Key Configuration:
├── Cargo.toml          (Rust deps)
├── CMakeLists.txt      (Qt build)
├── config.default.json (Default prefs)

Key Documentation:
├── README.md           (Overview)
├── DEVELOPMENT.md      (Dev guide)
├── ARCHITECTURE.md     (Design)
├── PROJECT_STATUS.md   (Completion)
```

## 🐛 DEBUGGING TIPS

```bash
# Verbose logging
RUST_LOG=debug RUST_BACKTRACE=1 ./build/rootlink

# Check inotify limits
cat /proc/sys/fs/inotify/max_user_watches

# Increase inotify limit
echo 524288 | sudo tee /proc/sys/fs/inotify/max_user_watches

# Profile with perf
perf record ./build/rootlink
perf report

# Memory check
valgrind --leak-check=full ./build/rootlink
```

## 🎯 ARCHITECTURE LAYERS

```
┌─────────────────┐
│  QML UI Layer   │  Grid/List/Column views
├─────────────────┤
│  QML Bridge     │  JSON communication
├─────────────────┤
│  Rust Backend   │  Async services
├─────────────────┤
│  Linux Kernel   │  Syscalls, Wayland
└─────────────────┘
```

## 📦 PROJECT STRUCTURE

```
rootlink/
├── src/             (Source code)
├── resources/       (Assets, config)
├── build/           (Build artifacts)
├── Cargo.toml       (Rust manifest)
├── CMakeLists.txt   (Qt config)
└── Documentation   (4 guides)
```

## 🚀 PERFORMANCE TARGETS

- Directory listing: <100ms
- Search: <50ms
- Animations: 60+ fps
- Memory: 100-300 MB
- Startup: <2 seconds

## 🔗 USEFUL LINKS

- [Qt6 Docs](https://doc.qt.io/qt-6/)
- [Rust Book](https://doc.rust-lang.org/book/)
- [Tokio Guide](https://tokio.rs/)
- [Wayland Protocol](https://wayland.freedesktop.org/)

## 💡 CODING PATTERNS

### Async Rust
```rust
pub async fn operation(&self) -> Result<T> {
    // Non-blocking operation
    Ok(result)
}
```

### QML Component
```qml
Rectangle {
    id: component
    property string data: ""
    signal actionTriggered()
    
    // Implementation
}
```

### JSON Serialization
```rust
#[derive(Serialize, Deserialize)]
pub struct Data { ... }

// To QML
serde_json::to_string(&data)?
```

## ✅ PRE-COMMIT CHECKLIST

- [ ] Code compiles
- [ ] Tests pass
- [ ] No warnings
- [ ] Formatted with rustfmt
- [ ] Documented changes
- [ ] Updated CHANGELOG

## 🤝 CODE REVIEW CHECKLIST

- [ ] Follows architecture
- [ ] Proper error handling
- [ ] Performance acceptable
- [ ] No security issues
- [ ] Well documented
- [ ] Tests included

---

**Last Updated**: 2024
**Project Status**: Production Ready ✅
