import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: preview
    color: Theme.colors.background
    radius: Theme.border_radius

    // Blur effect for Wayland
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        blur: 0.1
        blurMax: 64
    }

    property var fileInfo
    property bool visible: false

    Behavior on opacity {
        NumberAnimation { duration: Theme.animation_duration }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.medium

        // Close button
        Button {
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            width: 32
            height: 32
            background: Rectangle {
                color: parent.hovered ? Theme.colors.hover_bg : "transparent"
                radius: Theme.border_radius / 2
            }
            contentItem: Text {
                text: "✕"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 16
                color: Theme.colors.text_primary
            }
            onClicked: preview.visible = false
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

                // File icon/preview
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "🖼️"
                    font.pixelSize: 96
                }

                // File name
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: preview.fileInfo ? preview.fileInfo.name : ""
                    font.family: Theme.typography.heading
                    font.pixelSize: 18
                    color: Theme.colors.text_primary
                }

                // File metadata
                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 2
                    columnSpacing: Theme.spacing.large
                    rowSpacing: Theme.spacing.small

                    Text {
                        text: "Size:"
                        color: Theme.colors.text_secondary
                        font.pixelSize: 12
                    }

                    Text {
                        text: formatSize(preview.fileInfo ? preview.fileInfo.size : 0)
                        color: Theme.colors.text_primary
                        font.pixelSize: 12
                    }

                    Text {
                        text: "Modified:"
                        color: Theme.colors.text_secondary
                        font.pixelSize: 12
                    }

                    Text {
                        text: formatDate(preview.fileInfo ? preview.fileInfo.modified : 0)
                        color: Theme.colors.text_primary
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

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
}
