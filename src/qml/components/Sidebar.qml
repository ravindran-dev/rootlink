import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: sidebar
    width: 250
    color: Theme.colors.sidebar_bg
    
    signal navigateTo(string path)
    signal collapsed(bool collapsed)

    property bool isCollapsed: false
    property var favorites: [
        { name: "Desktop", path: "~/Desktop", icon: "🖥️" },
        { name: "Documents", path: "~/Documents", icon: "📄" },
        { name: "Downloads", path: "~/Downloads", icon: "⬇️" },
        { name: "Pictures", path: "~/Pictures", icon: "🖼️" },
    ]

    // Smooth collapse animation
    Behavior on width {
        NumberAnimation {
            duration: Theme.animation_duration
            easing.type: Easing.InOutCubic
        }
    }

    // Left border (subtle shadow)
    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.colors.border
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // Header with collapse button
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: Theme.colors.sidebar_bg
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacing.medium
                spacing: Theme.spacing.small

                Text {
                    text: "Rootlink"
                    visible: !sidebar.isCollapsed
                    font.family: Theme.typography.heading
                    font.pixelSize: 16
                    font.weight: Font.SemiBold
                    color: Theme.colors.text_primary
                    Layout.fillWidth: true
                }

                // Collapse button
                Button {
                    width: 32
                    height: 32
                    background: Rectangle {
                        color: hovered ? Theme.colors.hover_bg : "transparent"
                        radius: Theme.border_radius / 2
                    }
                    contentItem: Text {
                        text: sidebar.isCollapsed ? "→" : "←"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 14
                        color: Theme.colors.text_primary
                    }
                    onClicked: {
                        sidebar.isCollapsed = !sidebar.isCollapsed
                        sidebar.collapsed(sidebar.isCollapsed)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.colors.border
        }

        // Scrollable sidebar content
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: sidebar.width
                spacing: Theme.spacing.small

                // Favorites Section
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    color: "transparent"
                    
                    Text {
                        visible: !sidebar.isCollapsed
                        text: "FAVORITES"
                        x: Theme.spacing.medium
                        y: Theme.spacing.small
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.colors.text_secondary
                        letter_spacing: 0.5
                    }
                }

                Repeater {
                    model: sidebar.favorites
                    delegate: SidebarItem {
                        visible: !sidebar.isCollapsed
                        Layout.fillWidth: true
                        icon: modelData.icon
                        label: modelData.name
                        onClicked: sidebar.navigateTo(modelData.path)
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.colors.border
                    Layout.topMargin: Theme.spacing.medium
                    Layout.bottomMargin: Theme.spacing.medium
                }

                // Places Section
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    color: "transparent"
                    
                    Text {
                        visible: !sidebar.isCollapsed
                        text: "PLACES"
                        x: Theme.spacing.medium
                        y: Theme.spacing.small
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.colors.text_secondary
                    }
                }

                SidebarItem {
                    visible: !sidebar.isCollapsed
                    Layout.fillWidth: true
                    icon: "🏠"
                    label: "Home"
                    onClicked: sidebar.navigateTo("~/")
                }

                SidebarItem {
                    visible: !sidebar.isCollapsed
                    Layout.fillWidth: true
                    icon: "⭐"
                    label: "Recent"
                    onClicked: sidebar.navigateTo("/recent")
                }

                SidebarItem {
                    visible: !sidebar.isCollapsed
                    Layout.fillWidth: true
                    icon: "🔍"
                    label: "Search"
                    onClicked: sidebar.navigateTo("/search")
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.colors.border
                    Layout.topMargin: Theme.spacing.medium
                    Layout.bottomMargin: Theme.spacing.medium
                    visible: !sidebar.isCollapsed
                }

                // Devices Section
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    color: "transparent"
                    visible: !sidebar.isCollapsed
                    
                    Text {
                        text: "DEVICES"
                        x: Theme.spacing.medium
                        y: Theme.spacing.small
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.colors.text_secondary
                    }
                }

                // Mounted drives (would be populated from Rust backend)
                SidebarItem {
                    visible: !sidebar.isCollapsed
                    Layout.fillWidth: true
                    icon: "💾"
                    label: "System"
                    onClicked: sidebar.navigateTo("/")
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }

    function toggleHidden() {
        sidebar.isCollapsed = !sidebar.isCollapsed
    }
}
