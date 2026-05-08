# Architecture Document

## System Overview

Rootlink is a three-layer architecture:

```
┌─────────────────────────────────────────────────────────┐
│                  User Interface Layer                    │
│  Qt6/QML Components (Grid, List, Column Views, Toolbar) │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓ JSON/Async
┌─────────────────────────────────────────────────────────┐
│                   Bridge Layer                           │
│  Rust/Qt FFI (QML Bridge, Serialization, Event System) │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓ Async Operations
┌─────────────────────────────────────────────────────────┐
│                  Backend Layer                           │
│  Rust Services (Filesystem, Search, Thumbnails, Watch)  │
└─────────────────────────────────────────────────────────┘
                     │
                     ↓ System Calls
┌─────────────────────────────────────────────────────────┐
│              Operating System & Hardware                │
│  Linux Kernel, Wayland, Filesystem, Storage Devices    │
└─────────────────────────────────────────────────────────┘
```

## Data Flow

### File Browsing
```
User Action (Click)
  ↓
QML Event Handler
  ↓
Call Rust Backend (JSON)
  ↓
FilesystemService::list_directory()
  ↓
Read from Filesystem Cache or Disk
  ↓
Return FileInfo Array (JSON)
  ↓
Update QML Model
  ↓
Render UI
```

### Search Operation
```
User Types in Search
  ↓
QML Triggers Search After Debounce
  ↓
Call SearchEngine::search(query)
  ↓
SQLite FTS Query
  ↓
Return Results with Relevance Scores
  ↓
Update Search Results View
```

### Real-time Updates
```
File System Change (External Process)
  ↓
File Watcher Detects Change
  ↓
Send FileChangeEvent via Broadcast
  ↓
QML Event Handler Receives Update
  ↓
Invalidate Cache
  ↓
Refresh Directory View
```

## Component Interactions

### Filesystem Service
- **Dependency**: std::fs, Tokio
- **Provides**: File operations, directory listing, metadata
- **Used by**: QML Bridge, Search Engine, Thumbnail Manager
- **Caching**: DashMap-based LRU cache

### File Watcher
- **Dependency**: Notify crate
- **Provides**: Real-time change notifications
- **Used by**: QML Frontend (via bridge)
- **Mechanism**: Broadcast channel for events

### Search Engine
- **Dependency**: RuSQLite, Regex
- **Provides**: Indexed full-text search
- **Used by**: QML Frontend
- **Indexing**: Background directory scanning

### Thumbnail Manager
- **Dependency**: Image crate
- **Provides**: Thumbnail generation and caching
- **Used by**: File Grid View
- **Optimization**: Lazy loading, disk cache

### Theme System
- **Dependency**: Serde JSON
- **Provides**: Theme configuration and persistence
- **Used by**: QML Components
- **Features**: Light/dark mode, customization

## Key Design Decisions

### 1. Async Architecture
- **Why**: Non-blocking I/O operations
- **Implementation**: Tokio runtime
- **Benefit**: Responsive UI, better resource usage

### 2. Caching Strategy
- **Directory Listing**: DashMap in-memory cache
- **Thumbnails**: LRU cache + disk cache
- **Search Index**: SQLite database
- **Benefit**: Fast repeated access, reduced I/O

### 3. Modular Components
- **Design**: Each major feature in separate module
- **Communication**: Via QML bridge
- **Benefit**: Easy testing, maintainability

### 4. QML for UI
- **Why**: Declarative, GPU acceleration, cross-platform
- **Bridge**: Rust/Qt FFI for data transfer
- **Benefit**: Responsive, smooth animations

### 5. Wayland Native
- **Why**: Modern display server
- **Implementation**: No X11 compatibility layer
- **Benefit**: Better integration, reduced complexity

## Scalability Considerations

### Handle Large Directories
- Use ListView/GridView virtualization
- Only render visible items
- Lazy load thumbnails
- Implement pagination

### Memory Management
- Cache size limits with LRU eviction
- Thumbnail disk caching
- Stream large files
- Clean up temporary data

### Performance Optimization
- Use indexed search for large indexes
- Batch filesystem operations
- Async thumbnail generation
- Efficient path canonicalization

## Security Considerations

### File Operations
- Validate paths before access
- Check permissions before operations
- Handle symlinks safely
- Prevent directory traversal

### Search Indexing
- Respect file permissions
- Don't index sensitive files
- Clean up index on uninstall
- Cache in user-writable directory only

### Wayland Integration
- Use official Wayland APIs
- Validate drag-and-drop data
- Handle clipboard safely
- Respect window manager policies

## Error Handling

### Rust Backend
- Custom error types with thiserror
- Async error propagation
- Logging via tracing
- User-friendly messages

### QML Frontend
- Display error dialogs
- Retry mechanisms
- Graceful degradation
- Clear error messages

## Configuration & State

### Runtime Configuration
- `~/.config/rootlink/theme.json` - Theme settings
- `~/.config/rootlink/preferences.json` - User preferences
- `~/.config/rootlink/shortcuts.json` - Keyboard shortcuts

### Cache & Data
- `~/.cache/rootlink/thumbnails/` - Generated thumbnails
- `~/.cache/rootlink/search.db` - Search index
- `~/.cache/rootlink/sessions/` - Session data

## Future Architecture Improvements

### Plugins System
- Load third-party file handlers
- Custom context menu items
- Theme plugins

### Network Support
- SMB/NFS mounts
- SFTP/SSH support
- Cloud storage integration

### Advanced Features
- File compression integration
- Archive handling
- Media metadata reading
- Advanced permissions UI

## Performance Metrics

### Target Performance
- Directory listing: <100ms for 1000 files
- Search: <50ms for 10000 files
- Thumbnail generation: <200ms per image
- UI responsiveness: >60fps

### Profiling Points
- Directory scanning time
- Cache hit rates
- Memory usage patterns
- CPU utilization
- Disk I/O patterns
