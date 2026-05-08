import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: window
    title: "Rootlink - File Manager"
    width: 1200
    height: 800
    visible: true
    color: Theme.colors.background

    // Wayland-specific configuration
    flags: Qt.Window | Qt.NoDropShadowWindowHint
    
    // Enable GPU acceleration
    Component.onCompleted: {
        // Set window properties for Wayland
        setX(Screen.width / 2 - width / 2)
        setY(Screen.height / 2 - height / 2)
    }

    // Theme system
    property var currentTheme: Theme

    // Main layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Toolbar
        Toolbar {
            id: toolbar
            Layout.fillWidth: true
            height: 60
            onNavigateBack: fileBrowser.goBack()
            onNavigateForward: fileBrowser.goForward()
            onSearchQuery: fileBrowser.search(query)
            onViewModeChanged: fileBrowser.viewMode = mode
        }

        // Main content area with sidebar
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Left Sidebar
            Sidebar {
                id: sidebar
                width: 250
                Layout.fillHeight: true
                onNavigateTo: fileBrowser.navigate(path)
                onCollapsed: {
                    sidebar.width = collapsed ? 50 : 250
                }
            }

            // Main file browser area
            FileBrowser {
                id: fileBrowser
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentTheme: window.currentTheme
            }
        }

        // Status bar
        StatusBar {
            Layout.fillWidth: true
            height: 30
            fileCount: fileBrowser.fileCount
            totalSize: fileBrowser.totalSize
            selectedItems: fileBrowser.selectedItems.length
        }
    }

    // Keyboard shortcuts
    Shortcut {
        sequence: "Ctrl+H"
        onActivated: sidebar.toggleHidden()
    }

    Shortcut {
        sequence: "Ctrl+1"
        onActivated: fileBrowser.viewMode = "grid"
    }

    Shortcut {
        sequence: "Ctrl+2"
        onActivated: fileBrowser.viewMode = "list"
    }

    Shortcut {
        sequence: "Ctrl+3"
        onActivated: fileBrowser.viewMode = "column"
    }

    Shortcut {
        sequence: "Ctrl+F"
        onActivated: toolbar.focusSearch()
    }

    Shortcut {
        sequence: "Ctrl+T"
        onActivated: fileBrowser.newTab()
    }

    Shortcut {
        sequence: "Ctrl+W"
        onActivated: fileBrowser.closeTab()
    }

    Shortcut {
        sequence: "Ctrl+N"
        onActivated: fileBrowser.newWindow()
    }

    Shortcut {
        sequence: "Delete"
        onActivated: fileBrowser.deleteSelected()
    }

    Shortcut {
        sequence: "Ctrl+C"
        onActivated: fileBrowser.copy()
    }

    Shortcut {
        sequence: "Ctrl+V"
        onActivated: fileBrowser.paste()
    }

    Shortcut {
        sequence: "Ctrl+X"
        onActivated: fileBrowser.cut()
    }

    Shortcut {
        sequence: "Ctrl+A"
        onActivated: fileBrowser.selectAll()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: fileBrowser.clearSelection()
    }

    Shortcut {
        sequence: "Space"
        onActivated: fileBrowser.quickLook()
    }

    Shortcut {
        sequence: "Return"
        onActivated: fileBrowser.openSelected()
    }

    Shortcut {
        sequence: "Ctrl+,"
        onActivated: fileBrowser.openPreferences()
    }
}
