import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: gridItem
    color: selected ? Theme.colors.selected_bg : (mouseArea.containsMouse ? Theme.colors.hover_bg : "transparent")
    radius: Theme.border_radius
    
    property var fileInfo
    property bool selected: false
    
    signal clicked(var mouse)
    signal doubleClicked()

    Behavior on color {
        ColorAnimation { duration: Theme.animation_duration }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.small
        spacing: Theme.spacing.small

        // File icon/thumbnail
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: parent.width - Theme.spacing.medium
            height: width
            radius: Theme.border_radius / 2
            color: Theme.colors.foreground
            clip: true

            Text {
                anchors.centerIn: parent
                text: fileInfo.is_dir ? "📁" : getFileIcon(fileInfo.icon_name)
                font.pixelSize: 48
            }
        }

        // File name
        Text {
            Layout.fillWidth: true
            text: fileInfo.name
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.family: Theme.typography.body
            font.pixelSize: Theme.typography.bodySize - 1
            color: Theme.colors.text_primary
        }

        // File size
        Text {
            Layout.fillWidth: true
            text: formatSize(fileInfo.size)
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 11
            color: Theme.colors.text_secondary
            visible: !fileInfo.is_dir
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: gridItem.clicked(mouse)
        onDoubleClicked: gridItem.doubleClicked()
        onPressAndHold: {
            // Show context menu
        }
    }

    function getFileIcon(iconName) {
        const icons = {
            "folder": "📁",
            "file": "📄",
            "image": "🖼️",
            "video": "🎬",
            "audio": "🎵",
            "archive": "📦",
            "document-pdf": "📕",
            "document-text": "📝",
            "document-code": "💻",
            "executable": "⚙️",
        }
        return icons[iconName] || "📄"
    }

    function formatSize(bytes) {
        if (bytes === 0) return "0 B"
        const k = 1024
        const sizes = ["B", "KB", "MB", "GB"]
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return (bytes / Math.pow(k, i)).toFixed(1) + " " + sizes[i]
    }
}
