import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: statusBar
    color: Theme.colors.toolbar_bg
    
    property int fileCount: 0
    property int totalSize: 0
    property int selectedItems: 0

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Theme.colors.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.large
        anchors.rightMargin: Theme.spacing.large
        spacing: Theme.spacing.medium

        Text {
            text: {
                if (statusBar.selectedItems > 0) {
                    return statusBar.selectedItems + " item" + (statusBar.selectedItems > 1 ? "s" : "") + " selected"
                }
                return statusBar.fileCount + " item" + (statusBar.fileCount > 1 ? "s" : "")
            }
            font.pixelSize: 12
            color: Theme.colors.text_secondary
            Layout.fillWidth: true
        }

        Text {
            text: formatSize(statusBar.totalSize)
            font.pixelSize: 12
            color: Theme.colors.text_secondary
        }
    }

    function formatSize(bytes) {
        if (bytes === 0) return "0 B"
        const k = 1024
        const sizes = ["B", "KB", "MB", "GB", "TB"]
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return (bytes / Math.pow(k, i)).toFixed(1) + " " + sizes[i]
    }
}
