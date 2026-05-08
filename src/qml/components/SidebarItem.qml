import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: sidebarItem
    height: 44
    color: mouseArea.containsMouse ? Theme.colors.hover_bg : "transparent"
    radius: Theme.border_radius / 2
    
    property string icon: ""
    property string label: ""
    
    signal clicked()

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        spacing: Theme.spacing.medium

        Text {
            text: sidebarItem.icon
            font.pixelSize: 18
            Layout.preferredWidth: 20
        }

        Text {
            text: sidebarItem.label
            font.family: Theme.typography.body
            font.pixelSize: Theme.typography.bodySize
            color: Theme.colors.text_primary
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: sidebarItem.clicked()
    }
}
