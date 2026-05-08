import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: toolbar
    color: Theme.colors.toolbar_bg
    
    signal navigateBack()
    signal navigateForward()
    signal searchQuery(string query)
    signal viewModeChanged(string mode)

    // Toolbar blur effect for Wayland
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        blur: 0.2
        blurMax: 64
    }

    // Bottom border
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.colors.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.large
        anchors.rightMargin: Theme.spacing.large
        spacing: Theme.spacing.medium

        // Navigation buttons
        Button {
            id: backBtn
            width: 40
            height: 40
            background: Rectangle {
                radius: Theme.border_radius
                color: backBtn.hovered ? Theme.colors.hover_bg : "transparent"
            }
            contentItem: Text {
                text: "←"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 16
                color: Theme.colors.text_primary
            }
            onClicked: toolbar.navigateBack()
        }

        Button {
            id: forwardBtn
            width: 40
            height: 40
            background: Rectangle {
                radius: Theme.border_radius
                color: forwardBtn.hovered ? Theme.colors.hover_bg : "transparent"
            }
            contentItem: Text {
                text: "→"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 16
                color: Theme.colors.text_primary
            }
            onClicked: toolbar.navigateForward()
        }

        // Separator
        Rectangle {
            width: 1
            height: 24
            color: Theme.colors.border
        }

        // Search bar
        SearchBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            onSearch: toolbar.searchQuery(query)
        }

        // View mode buttons
        RowLayout {
            spacing: Theme.spacing.small

            Button {
                width: 36
                height: 36
                background: Rectangle {
                    radius: Theme.border_radius / 2
                    color: parent.checked ? Theme.colors.accent : (parent.hovered ? Theme.colors.hover_bg : "transparent")
                }
                contentItem: Text {
                    text: "⊞"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    color: parent.checked ? "white" : Theme.colors.text_primary
                }
                checkable: true
                checked: true
                onClicked: {
                    listViewBtn.checked = false
                    columnViewBtn.checked = false
                    toolbar.viewModeChanged("grid")
                }
            }

            Button {
                id: listViewBtn
                width: 36
                height: 36
                background: Rectangle {
                    radius: Theme.border_radius / 2
                    color: parent.checked ? Theme.colors.accent : (parent.hovered ? Theme.colors.hover_bg : "transparent")
                }
                contentItem: Text {
                    text: "≡"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    color: parent.checked ? "white" : Theme.colors.text_primary
                }
                checkable: true
                onClicked: {
                    backBtn.checked = false
                    columnViewBtn.checked = false
                    toolbar.viewModeChanged("list")
                }
            }

            Button {
                id: columnViewBtn
                width: 36
                height: 36
                background: Rectangle {
                    radius: Theme.border_radius / 2
                    color: parent.checked ? Theme.colors.accent : (parent.hovered ? Theme.colors.hover_bg : "transparent")
                }
                contentItem: Text {
                    text: "⋮"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    color: parent.checked ? "white" : Theme.colors.text_primary
                }
                checkable: true
                onClicked: {
                    backBtn.checked = false
                    listViewBtn.checked = false
                    toolbar.viewModeChanged("column")
                }
            }
        }

        // Action buttons
        Button {
            width: 40
            height: 40
            background: Rectangle {
                radius: Theme.border_radius
                color: parent.hovered ? Theme.colors.hover_bg : "transparent"
            }
            contentItem: Text {
                text: "⋯"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 16
                color: Theme.colors.text_primary
            }
            onClicked: {
                // Show menu
            }
        }
    }

    function focusSearch() {
        // Focus search bar
    }
}
