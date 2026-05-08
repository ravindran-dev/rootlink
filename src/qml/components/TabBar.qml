import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: tabBar
    color: Theme.colors.foreground
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.small
        spacing: Theme.spacing.small

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            spacing: Theme.spacing.small
            clip: true

            model: 3 // Example: 3 tabs

            delegate: Rectangle {
                width: 150
                height: tabBar.height - Theme.spacing.medium
                radius: Theme.border_radius / 2
                color: index === 0 ? Theme.colors.accent : Theme.colors.hover_bg

                Text {
                    anchors.centerIn: parent
                    text: "Tab " + (index + 1)
                    color: index === 0 ? "white" : Theme.colors.text_primary
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // Switch to this tab
                    }
                }
            }
        }

        // New tab button
        Button {
            width: 36
            height: 36
            background: Rectangle {
                color: parent.hovered ? Theme.colors.hover_bg : "transparent"
                radius: Theme.border_radius / 2
            }
            contentItem: Text {
                text: "+"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 16
                color: Theme.colors.text_primary
            }
            onClicked: {
                // Create new tab
            }
        }
    }
}
