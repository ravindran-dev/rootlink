# Development Guide

## Project Overview

Rootlink is a modern file manager for Sway/Wayland written in Rust and Qt6/QML. This guide helps developers understand the architecture and contribute effectively.

## Architecture

### Rust Backend (`src/rust/`)

The Rust backend provides all core functionality:

#### `main.rs` - Entry Point
- Initializes logging
- Creates service instances
- Starts the async runtime
- Bridges to QML

#### `filesystem.rs` - File Operations
- Lists directories with caching
- Gets file metadata (size, permissions, etc.)
- Handles copy/move/delete operations
- Manages symlinks
- Detects mounted drives
- Handles file permissions

**Key types:**
- `FileInfo` - File metadata
- `DirectoryListing` - Directory contents
- `FilesystemService` - Main service

**Performance features:**
- DashMap cache for directory listings
- Async operations via Tokio
- Efficient path normalization

#### `filewatcher.rs` - Real-time Monitoring
- Watches filesystem for changes
- Debounces rapid events
- Broadcasts changes via broadcast channel
- Handles recursive directory watching

**Key types:**
- `FileChangeEvent` - Change notification
- `FileWatcher` - Main watcher service

#### `search.rs` - Search Engine
- SQLite-based full-text search
- Relevance scoring
- Directory indexing
- Query optimization

**Key types:**
- `SearchResult` - Search result entry
- `SearchEngine` - Main search service

#### `thumbnails.rs` - Thumbnail Generation
- Async thumbnail generation
- Memory and disk caching
- LRU cache management
- Supports images, PDFs, videos

**Key types:**
- `Thumbnail` - Generated thumbnail
- `ThumbnailManager` - Main manager

#### `qml_bridge.rs` - Rust/Qt Integration
- Bridges Rust backend to QML frontend
- Serializes data to JSON
- Handles async operations
- Manages theme state

#### `theme.rs` - Theme Management
- Light/dark mode support
- Serializable theme configuration
- System preference detection
- Configuration file management

#### `errors.rs` - Error Handling
- Centralized error types
- Thiserror integration
- Custom error messages

### QML Frontend (`src/qml/`)

The QML frontend provides the user interface:

#### Pages (`pages/`)
- `FileBrowser.qml` - Main file browsing interface
- `QuickLook.qml` - Space-bar preview system
- `Preferences.qml` - Settings interface

#### Components (`components/`)
- `Sidebar.qml` - Navigation sidebar
- `Toolbar.qml` - Top toolbar with controls
- `FileGrid.qml` - Grid view item
- `FileListView.qml` - List view item
- `ColumnView.qml` - Column browser view
- `PathBar.qml` - Breadcrumb navigation
- `SearchBar.qml` - Search input
- `StatusBar.qml` - Bottom status display
- `ContextMenu.qml` - Right-click menu
- `TabBar.qml` - Multi-tab interface
- `PreviewPanel.qml` - File preview panel
- `SidebarItem.qml` - Sidebar navigation item

#### Theme System (`theme/`)
- `Colors.qml` - Color definitions
- `Typography.qml` - Font configuration
- `Spacing.qml` - Layout spacing
- `Theme.qml` - Master theme module

### Build System

- `Cargo.toml` - Rust dependencies and configuration
- `CMakeLists.txt` - Qt/C++ build configuration
- `build.sh` - Build automation script

## Development Workflow

### Running in Development Mode

```bash
# Terminal 1: Continuous build
cargo watch -x build

# Terminal 2: Run application
RUST_LOG=debug ./build/rootlink
```

### Code Organization

1. **Rust Code**
   - One module per file in `src/rust/`
   - Async operations with Tokio
   - Error handling with thiserror
   - Logging with tracing

2. **QML Code**
   - One component per file
   - Consistent naming (PascalCase)
   - Properties and signals at top
   - Functions at bottom

3. **Styling**
   - Use Theme module for all colors
   - Consistent spacing with Spacing module
   - Typography through Typography module

## Adding Features

### Example: Add a New File Operation

1. **Add Rust function** (`src/rust/filesystem.rs`)
```rust
pub async fn compress(&self, path: &Path) -> Result<PathBuf, FilesystemError> {
    // Implementation
}
```

2. **Expose to QML** (`src/rust/qml_bridge.rs`)
```rust
pub async fn compress(&self, path: &str) -> Result<String, String> {
    // Call filesystem service
}
```

3. **Add QML UI** (`src/qml/components/ContextMenu.qml`)
```qml
MenuItem {
    text: "Compress"
    onClicked: backend.compress(selectedFile)
}
```

### Example: Add a New View Mode

1. **Create view component** (`src/qml/components/IconView.qml`)
2. **Add to FileBrowser** (`src/qml/main.qml`)
3. **Add toolbar button** (`src/qml/components/Toolbar.qml`)
4. **Add keyboard shortcut** (`src/qml/main.qml`)

## Performance Considerations

### Rust Backend

- Use async/await for I/O operations
- Cache frequently accessed data
- Batch operations when possible
- Use appropriate data structures (DashMap, Vec)

### QML Frontend

- Use ListView/GridView with models
- Implement virtualization for large lists
- Minimize animations on low-end hardware
- Profile with Qt Creator

### General

- Monitor memory usage
- Profile with perf/valgrind
- Optimize hot paths
- Use lazy loading

## Testing

### Unit Tests (Rust)

```bash
cargo test --release
```

### Integration Tests

```bash
# Manual testing
cargo build --release
./build/rootlink
```

## Debugging

### Rust Backend

```bash
RUST_LOG=debug cargo run --release
RUST_BACKTRACE=1 cargo run
```

### QML Frontend

```bash
QT_DEBUG_PLUGINS=1 ./build/rootlink
QML_IMPORT_TRACE=1 ./build/rootlink
```

### General Issues

1. **File watcher not working**
   - Check inotify limits: `cat /proc/sys/fs/inotify/max_user_watches`
   - Increase if needed

2. **UI not responsive**
   - Check for blocking operations
   - Use async operations
   - Profile with Qt Creator

3. **Memory leaks**
   - Use valgrind: `valgrind --leak-check=full ./build/rootlink`
   - Check Qt signal connections

## Contributing Code

1. **Code Style**
   - Format Rust with `rustfmt`
   - Follow Qt conventions for C++
   - 4-space indentation for QML

2. **Documentation**
   - Comment complex logic
   - Document public APIs
   - Update README for features

3. **Testing**
   - Write tests for new functions
   - Test on real hardware
   - Verify keyboard shortcuts

4. **Commit Messages**
   - Use clear, descriptive messages
   - Reference issues when applicable
   - Use conventional commits

## Resources

- [Qt6 Documentation](https://doc.qt.io/qt-6/)
- [Rust Book](https://doc.rust-lang.org/book/)
- [Tokio Documentation](https://tokio.rs/)
- [Wayland Protocol](https://wayland.freedesktop.org/)
- [Linux Filesystem API](https://man7.org/linux/man-pages/)

## Reporting Issues

When reporting issues, include:

1. System information
   - Linux distribution
   - Sway version
   - Qt6 version

2. Steps to reproduce
3. Expected behavior
4. Actual behavior
5. Debug logs (`RUST_LOG=debug`)

## Questions?

- Check existing issues
- Review code comments
- Ask in discussions
- Check documentation

Happy coding! 🎉
