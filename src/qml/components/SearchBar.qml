import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: searchBar
    color: Theme.colors.foreground
    radius: Theme.border_radius
    border.color: Theme.colors.border
    border.width: 1
    
    signal search(string query)

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.small
        spacing: Theme.spacing.small

        Text {
            text: "🔍"
            font.pixelSize: 14
            color: Theme.colors.text_secondary
        }

        TextField {
            id: searchInput
            Layout.fillWidth: true
            Layout.fillHeight: true
            background: Rectangle {
                color: "transparent"
            }
            placeholderText: "Search files..."
            placeholderTextColor: Theme.colors.text_secondary
            font.family: Theme.typography.body
            font.pixelSize: Theme.typography.bodySize
            color: Theme.colors.text_primary

            onTextChanged: {
                searchDelayTimer.restart()
            }
        }

        // Clear button
        Button {
            visible: searchInput.text.length > 0
            width: 24
            height: 24
            background: Rectangle {
                color: parent.hovered ? Theme.colors.hover_bg : "transparent"
                radius: 4
            }
            contentItem: Text {
                text: "✕"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                color: Theme.colors.text_primary
            }
            onClicked: {
                searchInput.text = ""
            }
        }
    }

    // Debounce search
    Timer {
        id: searchDelayTimer
        interval: 300
        running: false
        repeat: false
        onTriggered: {
            if (searchInput.text.length > 0) {
                searchBar.search(searchInput.text)
            }
        }
    }
}
