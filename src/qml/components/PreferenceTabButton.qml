import QtQuick
import QtQuick.Controls

Button {
    id: tabButton
    
    property bool active: false
    
    background: Rectangle {
        color: tabButton.active ? Theme.colors.accent : "transparent"
        radius: Theme.border_radius / 2
    }
    
    contentItem: Text {
        text: tabButton.text
        color: tabButton.active ? "white" : Theme.colors.text_primary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: Theme.typography.body
        font.pixelSize: Theme.typography.bodySize
    }
    
    onClicked: tabButton.active = !tabButton.active
}
