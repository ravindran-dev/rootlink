import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: quickLook
    color: Qt.rgba(0, 0, 0, 0.7)
    visible: false
    z: 1000

    // Backdrop blur
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        blur: 0.8
        blurMax: 64
    }

    Behavior on opacity {
        NumberAnimation { duration: Theme.animation_duration }
    }

    property var fileInfo

    // Center preview box
    Rectangle {
        id: previewBox
        anchors.centerIn: parent
        width: Math.min(800, parent.width - 100)
        height: Math.min(600, parent.height - 100)
        color: Theme.colors.background
        radius: Theme.border_radius
        visible: quickLook.visible

        scale: quickLook.visible ? 1 : 0.9
        opacity: quickLook.visible ? 1 : 0

        Behavior on scale {
            NumberAnimation { duration: Theme.animation_duration }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animation_duration }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing.large
            spacing: Theme.spacing.medium

            // Header with filename
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40

                Text {
                    text: quickLook.fileInfo ? quickLook.fileInfo.name : "Preview"
                    font.family: Theme.typography.heading
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: Theme.colors.text_primary
                    Layout.fillWidth: true
                }

                // Close button
                Button {
                    width: 40
                    height: 40
                    background: Rectangle {
                        color: parent.hovered ? Theme.colors.hover_bg : "transparent"
                        radius: Theme.border_radius / 2
                    }
                    contentItem: Text {
                        text: "✕"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 18
                        color: Theme.colors.text_primary
                    }
                    onClicked: quickLook.visible = false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.colors.border
            }

            // Preview content
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.colors.foreground
                radius: Theme.border_radius

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacing.large

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "🖼️"
                        font.pixelSize: 128
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Preview not available for this file type"
                        color: Theme.colors.text_secondary
                        font.pixelSize: 14
                    }
                }
            }

            // Footer with file info
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: Theme.colors.foreground
                radius: Theme.border_radius

                GridLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.medium
                    columns: 4
                    columnSpacing: Theme.spacing.large
                    rowSpacing: Theme.spacing.small

                    Column {
                        Text {
                            text: "Size"
                            color: Theme.colors.text_secondary
                            font.pixelSize: 11
                        }
                        Text {
                            text: formatSize(quickLook.fileInfo ? quickLook.fileInfo.size : 0)
                            color: Theme.colors.text_primary
                            font.pixelSize: 13
                        }
                    }

                    Column {
                        Text {
                            text: "Modified"
                            color: Theme.colors.text_secondary
                            font.pixelSize: 11
                        }
                        Text {
                            text: formatDate(quickLook.fileInfo ? quickLook.fileInfo.modified : 0)
                            color: Theme.colors.text_primary
                            font.pixelSize: 13
                        }
                    }

                    Column {
                        Text {
                            text: "Type"
                            color: Theme.colors.text_secondary
                            font.pixelSize: 11
                        }
                        Text {
                            text: quickLook.fileInfo ? quickLook.fileInfo.mime_type : "Unknown"
                            color: Theme.colors.text_primary
                            font.pixelSize: 13
                        }
                    }

                    Column {
                        Text {
                            text: "Permissions"
                            color: Theme.colors.text_secondary
                            font.pixelSize: 11
                        }
                        Text {
                            text: formatPermissions(quickLook.fileInfo ? quickLook.fileInfo.permissions : 0)
                            color: Theme.colors.text_primary
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    // Close on background click or ESC
    MouseArea {
        anchors.fill: parent
        onClicked: quickLook.visible = false
    }

    Keys.onEscapePressed: quickLook.visible = false

    function formatSize(bytes) {
        if (bytes === 0) return "0 B"
        const k = 1024
        const sizes = ["B", "KB", "MB", "GB"]
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return (bytes / Math.pow(k, i)).toFixed(1) + " " + sizes[i]
    }

    function formatDate(timestamp) {
        const date = new Date(timestamp * 1000)
        return date.toLocaleDateString()
    }

    function formatPermissions(mode) {
        let octal = "0" + (mode & parseInt("777", 8)).toString(8)
        return octal
    }
}
