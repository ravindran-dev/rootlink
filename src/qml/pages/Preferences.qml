import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: preferences
    color: Theme.colors.background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.large

        // Preferences header
        Text {
            text: "Preferences"
            font.family: Theme.typography.heading
            font.pixelSize: 28
            font.weight: Font.Bold
            color: Theme.colors.text_primary
        }

        // Tabbed preferences
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacing.medium

            // Sidebar with tabs
            Rectangle {
                Layout.preferredWidth: 150
                Layout.fillHeight: true
                color: Theme.colors.foreground
                radius: Theme.border_radius

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.medium
                    spacing: Theme.spacing.small

                    PreferenceTabButton {
                        Layout.fillWidth: true
                        text: "General"
                    }

                    PreferenceTabButton {
                        Layout.fillWidth: true
                        text: "Appearance"
                    }

                    PreferenceTabButton {
                        Layout.fillWidth: true
                        text: "Behavior"
                    }

                    PreferenceTabButton {
                        Layout.fillWidth: true
                        text: "Advanced"
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // Content area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.colors.foreground
                radius: Theme.border_radius

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.large
                    spacing: Theme.spacing.large

                    // General settings
                    GroupBox {
                        Layout.fillWidth: true
                        title: "General Settings"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Theme.spacing.medium

                            RowLayout {
                                Text {
                                    text: "Show Hidden Files"
                                    Layout.fillWidth: true
                                }
                                Switch {
                                    checked: true
                                }
                            }

                            RowLayout {
                                Text {
                                    text: "Default View"
                                    Layout.fillWidth: true
                                }
                                ComboBox {
                                    model: ["Grid", "List", "Column"]
                                    Layout.preferredWidth: 120
                                }
                            }

                            RowLayout {
                                Text {
                                    text: "Show File Extensions"
                                    Layout.fillWidth: true
                                }
                                Switch {
                                    checked: true
                                }
                            }
                        }
                    }

                    // Appearance settings
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Appearance"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Theme.spacing.medium

                            RowLayout {
                                Text {
                                    text: "Theme"
                                    Layout.fillWidth: true
                                }
                                ComboBox {
                                    model: ["Light", "Dark", "System"]
                                    Layout.preferredWidth: 120
                                }
                            }

                            RowLayout {
                                Text {
                                    text: "Enable Blur Effects"
                                    Layout.fillWidth: true
                                }
                                Switch {
                                    checked: true
                                }
                            }

                            RowLayout {
                                Text {
                                    text: "Animation Speed"
                                    Layout.fillWidth: true
                                }
                                Slider {
                                    Layout.preferredWidth: 120
                                    from: 0
                                    to: 1
                                    value: 0.5
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom

            Item { Layout.fillWidth: true }

            Button {
                text: "Cancel"
                onClicked: preferences.visible = false
            }

            Button {
                text: "Save"
                background: Rectangle {
                    color: Theme.colors.accent
                    radius: Theme.border_radius / 2
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                onClicked: {
                    // Save preferences
                    preferences.visible = false
                }
            }
        }
    }
}
