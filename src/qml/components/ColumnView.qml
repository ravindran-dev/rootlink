import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: columnView
    color: Theme.colors.background
    
    property var fileModel: []
    signal fileSelected(var file)

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Column 1: Breadcrumb/folders
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 200
            color: Theme.colors.foreground
            border.color: Theme.colors.border
            border.width: 1

            ListView {
                anchors.fill: parent
                model: fileModel
                clip: true

                delegate: Rectangle {
                    width: parent.width
                    height: 44
                    color: mouseArea.containsMouse ? Theme.colors.hover_bg : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacing.medium
                        spacing: Theme.spacing.small

                        Text {
                            text: modelData.is_dir ? "📁" : "📄"
                            font.pixelSize: 16
                        }

                        Text {
                            text: modelData.name
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            color: Theme.colors.text_primary
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        onClicked: columnView.fileSelected(modelData)
                    }
                }
            }
        }

        // Column 2: Preview (would show preview of selected item)
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: Theme.colors.background

            Text {
                anchors.centerIn: parent
                text: "Column Preview"
                color: Theme.colors.text_secondary
            }
        }
    }
}
