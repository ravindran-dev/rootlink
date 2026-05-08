pragma Singleton
import QtQuick

QtObject {
    id: spacing

    // Base spacing unit (4px)
    readonly property int base: 4

    // Spacing scale
    readonly property int tiny: base * 1      // 4px
    readonly property int small: base * 2     // 8px
    readonly property int medium: base * 3    // 12px
    readonly property int large: base * 4     // 16px
    readonly property int xlarge: base * 5    // 20px
    readonly property int xxlarge: base * 6   // 24px

    // Standard margins
    readonly property int marginSmall: 8
    readonly property int marginMedium: 16
    readonly property int marginLarge: 24

    // Standard paddings
    readonly property int paddingSmall: 8
    readonly property int paddingMedium: 12
    readonly property int paddingLarge: 16

    // Component heights
    readonly property int buttonHeight: 36
    readonly property int inputHeight: 40
    readonly property int rowHeight: 44
    readonly property int toolbarHeight: 60
    readonly property int statusBarHeight: 30
}
