import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: pathBar
    color: Theme.colors.toolbar_bg
    
    property string currentPath: "/"
    property var previousPath: ""
    property var nextPath: ""
    
    signal pathSelected(string path)

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        spacing: Theme.spacing.small

        // Home button
        Button {
            width: 32
            height: 32
            background: Rectangle {
                color: parent.hovered ? Theme.colors.hover_bg : "transparent"
                radius: Theme.border_radius / 2
            }
            contentItem: Text {
                text: "🏠"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 14
            }
            onClicked: pathBar.pathSelected("/")
        }

        // Breadcrumb path
        Item {
            Layout.fillWidth: true
            height: 32

            RowLayout {
                anchors.fill: parent
                spacing: 4

                Repeater {
                    id: repeater
                    model: pathBar.currentPath.split("/").filter(x => x)
                    
                    RowLayout {
                        spacing: 4

                        Button {
                            text: modelData
                            background: Rectangle {
                                color: parent.hovered ? Theme.colors.hover_bg : "transparent"
                                radius: Theme.border_radius / 2
                            }
                            contentItem: Text {
                                text: parent.text
                                color: Theme.colors.text_primary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 13
                            }
                            onClicked: {
                                const parts = pathBar.currentPath.split("/").slice(0, index + 2)
                                pathBar.pathSelected("/" + parts.join("/"))
                            }
                        }

                        Text {
                            text: "/"
                            color: Theme.colors.text_secondary
                            visible: index < repeater.count - 1
                        }
                    }
                }
            }
        }

        // Location field (editable)
        TextField {
            id: locationField
            visible: false
            Layout.fillWidth: true
            text: pathBar.currentPath
            onAccepted: {
                pathBar.pathSelected(text)
                visible = false
            }
            Keys.onEscapePressed: {
                visible = false
            }
        }

        // Toggle location field
        Button {
            width: 32
            height: 32
            background: Rectangle {
                color: parent.hovered ? Theme.colors.hover_bg : "transparent"
                radius: Theme.border_radius / 2
            }
            contentItem: Text {
                text: "✎"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 14
                color: Theme.colors.text_primary
            }
            onClicked: {
                locationField.visible = !locationField.visible
                if (locationField.visible) {
                    locationField.forceActiveFocus()
                }
            }
        }
    }
}
