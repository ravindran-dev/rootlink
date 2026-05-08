pragma Singleton
import QtQuick

QtObject {
    id: colors

    // Current theme (will be set dynamically)
    property bool isDark: false

    property color background: isDark ? "#101216" : "#f7f7f6"
    property color surface: isDark ? "#151820" : "#ffffff"
    property color previewSurface: isDark ? "#1d222c" : "#ffffff"
    property color sidebarGlass: isDark ? "#f0181b22" : "#eff3f3f2"
    property color toolbarGlass: isDark ? "#f013161c" : "#f6ffffff"
    property color statusBar: isDark ? "#f014171d" : "#f7ffffff"
    property color control: isDark ? "#252a33" : "#ffffff"
    property color controlHover: isDark ? "#303641" : "#f1f1f1"
    property color controlPressed: isDark ? "#3b4350" : "#e4e4e4"
    property color panelSubtle: isDark ? "#202632" : "#ffffff"
    property color tileHover: isDark ? "#232a35" : "#f4f4f4"
    property color selection: isDark ? "#203c5c" : "#e8f2ff"
    property color sidebarHover: isDark ? "#282f3a" : "#e8e8e8"
    property color accent: isDark ? "#4aa3ff" : "#007aff"
    property color accentSoft: isDark ? "#1d3654" : "#dcecff"
    property color folderBack: isDark ? "#2379b8" : "#58bee9"
    property color folderTab: isDark ? "#3aa1df" : "#35aee2"
    property color fileBack: isDark ? "#2c3340" : "#ffffff"
    property color typeImage: isDark ? "#1f7a6d" : "#64c6b8"
    property color typeVideo: isDark ? "#7658ce" : "#a58cff"
    property color typeAudio: isDark ? "#b45b7b" : "#f199b5"
    property color typePdf: isDark ? "#bc4c46" : "#ff7f76"
    property color typeCode: isDark ? "#4b6587" : "#8aa6cc"
    property color typeArchive: isDark ? "#8d6d31" : "#d9b45f"
    property color typeText: isDark ? "#58616d" : "#c9c5bb"
    property color typeTextOnColor: "#ffffff"
    property color textPrimary: isDark ? "#f3f5f8" : "#2b2b2d"
    property color textMuted: isDark ? "#a3adbc" : "#6d6d72"
    property color textFaint: isDark ? "#697484" : "#a8a8ad"
    property color divider: isDark ? "#2b313c" : "#e5e5e7"
    property color hairline: isDark ? "#343b48" : "#e2e2e5"
    property color windowStroke: isDark ? "#303744" : "#d8d8dc"

    // Compatibility aliases for older components.
    property color foreground: previewSurface
    property color sidebar_bg: sidebarGlass
    property color toolbar_bg: toolbarGlass
    property color border: divider
    property color text_primary: textPrimary
    property color text_secondary: textMuted
    property color hover_bg: tileHover
    property color selected_bg: selection
}
