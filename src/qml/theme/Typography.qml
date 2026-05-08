pragma Singleton
import QtQuick

QtObject {
    id: typography

    // Font families
    property string heading: "JetBrainsMono Nerd Font"
    property string body: "JetBrainsMono Nerd Font"
    property string monospace: "JetBrainsMono Nerd Font Mono"
    property string icon: "Symbols Nerd Font"

    // Font sizes
    property int titleSize: 28
    property int headingSize: 18
    property int bodySize: 13
    property int captionSize: 11
    property int tinySize: 10

    // Font weights
    property int weightThin: 100
    property int weightLight: 300
    property int weightRegular: 400
    property int weightMedium: 500
    property int weightSemibold: 600
    property int weightBold: 700
}
