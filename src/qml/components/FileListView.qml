import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: listItem
    height: 44
    color: selected ? Theme.colors.selected_bg : (mouseArea.containsMouse ? Theme.colors.hover_bg : "transparent")
    
    property var fileInfo
    property bool selected: false
    
    signal clicked(var mouse)
    signal doubleClicked()

    Behavior on color {
        ColorAnimation { duration: Theme.animation_duration / 2 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        spacing: Theme.spacing.medium

        // Icon
        Text {
            text: fileInfo.is_dir ? "📁" : getFileIcon(fileInfo.icon_name)
            font.pixelSize: 18
            Layout.preferredWidth: 20
        }

        // Name
        Text {
            text: fileInfo.name
            font.family: Theme.typography.body
            font.pixelSize: Theme.typography.bodySize
            color: Theme.colors.text_primary
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        // Modified date
        Text {
            text: formatDate(fileInfo.modified)
            font.pixelSize: 12
            color: Theme.colors.text_secondary
            Layout.preferredWidth: 100
        }

        // Size
        Text {
            text: fileInfo.is_dir ? "—" : formatSize(fileInfo.size)
            font.pixelSize: 12
            color: Theme.colors.text_secondary
            Layout.preferredWidth: 80
            horizontalAlignment: Text.AlignRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: listItem.clicked(mouse)
        onDoubleClicked: listItem.doubleClicked()
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

    function formatDate(timestamp) {
        const date = new Date(timestamp * 1000)
        return date.toLocaleDateString()
    }
}
