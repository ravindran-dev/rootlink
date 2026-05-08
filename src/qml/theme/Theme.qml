pragma Singleton
import QtQuick

QtObject {
    id: theme

    // Import sub-theme modules
    property QtObject colors: Colors
    property QtObject typography: Typography
    property QtObject spacing: Spacing

    // Animation durations
    property int animation_duration: 200
    property int animation_duration_long: 400
    property int animation_duration_short: 100

    // Border radius
    property real border_radius: 12

    property QtObject radius: QtObject {
        property real window: 22
        property real panel: 18
        property real control: 14
        property real tile: 18
    }

    // Shadow properties
    property int shadow_blur: 20
    property int shadow_offset_y: 4

    // Opacity values
    property real opacity_hover: 0.8
    property real opacity_disabled: 0.5
    property real opacity_subtle: 0.3

    // Z-order values
    property int z_toolbar: 100
    property int z_sidebar: 90
    property int z_menu: 200
    property int z_dialog: 300
    property int z_tooltip: 250

    // Component-specific properties
    property QtObject button: QtObject {
        property int height: 36
        property int radius: 8
        property string fontFamily: "SF Pro Display"
    }

    property QtObject input: QtObject {
        property int height: 40
        property int radius: 8
        property string fontFamily: "SF Pro Display"
    }

    // Wayland-specific settings
    property bool blur_enabled: true
    property bool transparency_enabled: true

    // Get theme based on system preference
    function isDarkMode() {
        return Qt.platform.os === "wayland" ? true : false
    }

    // Animation easings
    function easeInOutCubic(t) {
        return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
    }
}
