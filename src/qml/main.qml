import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt.labs.folderlistmodel
import "theme"

ApplicationWindow {
    id: root

    width: 1240
    height: 820
    minimumWidth: 940
    minimumHeight: 620
    visible: true
    title: "Rootlink"
    color: "transparent"

    property string currentPath: initialPath || homePath || "/"
    property string viewMode: "grid"
    property var selectedPaths: []
    property var backStack: []
    property var forwardStack: []
    property string searchText: ""
    property real iconScale: 1.0
    property var contextFile: ({})
    property var clipboardPaths: []
    property string clipboardMode: ""
    property int visibleCount: visibleModel.count
    readonly property bool darkMode: Theme.colors.isDark

    function fileUrl(path) {
        return "file://" + path
    }

    function displayPath(path) {
        if (homePath && path.indexOf(homePath) === 0) {
            const suffix = path.slice(homePath.length)
            return "~" + (suffix.length ? suffix : "")
        }
        return path
    }

    function navigate(path, pushHistory) {
        if (!path || path === currentPath) {
            return
        }
        if (pushHistory !== false) {
            backStack = backStack.concat([currentPath])
            forwardStack = []
        }
        selectedPaths = []
        currentPath = path
        folderModel.folder = fileUrl(path)
        refreshVisibleModel()
    }

    function goBack() {
        if (!backStack.length) {
            return
        }
        const previousPath = backStack[backStack.length - 1]
        backStack = backStack.slice(0, backStack.length - 1)
        forwardStack = forwardStack.concat([currentPath])
        navigate(previousPath, false)
    }

    function goForward() {
        if (!forwardStack.length) {
            return
        }
        const nextPath = forwardStack[forwardStack.length - 1]
        forwardStack = forwardStack.slice(0, forwardStack.length - 1)
        backStack = backStack.concat([currentPath])
        navigate(nextPath, false)
    }

    function toggleSelection(path, modifiers) {
        if (modifiers & Qt.ControlModifier) {
            const index = selectedPaths.indexOf(path)
            if (index >= 0) {
                selectedPaths.splice(index, 1)
                selectedPaths = selectedPaths.slice()
            } else {
                selectedPaths = selectedPaths.concat([path])
            }
        } else {
            selectedPaths = [path]
        }
    }

    function activate(path, isDir) {
        if (isDir) {
            navigate(path)
        } else {
        Qt.openUrlExternally(fileUrl(path))
        }
    }

    function refreshVisibleModel() {
        if (!visibleModel) {
            return
        }
        visibleModel.clear()
        const query = searchText.trim().toLowerCase()
        for (let i = 0; i < folderModel.count; i++) {
            const fileName = folderModel.get(i, "fileName")
            if (query.length && fileName.toLowerCase().indexOf(query) < 0) {
                continue
            }
            visibleModel.append({
                name: fileName,
                path: folderModel.get(i, "filePath"),
                isDir: folderModel.get(i, "fileIsDir"),
                size: folderModel.get(i, "fileSize"),
                modified: folderModel.get(i, "fileModified")
            })
        }
    }

    function openContextMenu(file, mouse) {
        contextFile = file
        if (selectedPaths.indexOf(file.path) < 0) {
            selectedPaths = [file.path]
        }
        fileContextMenu.popup()
    }

    function openFolderContextMenu(mouse) {
        contextFile = ({})
        selectedPaths = []
        fileContextMenu.popup()
    }

    function fileNameFromPath(path) {
        const slash = path.lastIndexOf("/")
        return slash >= 0 ? path.slice(slash + 1) : path
    }

    function clipboardSourcePaths() {
        if (selectedPaths.length) {
            return selectedPaths.slice()
        }
        if (contextFile.path) {
            return [contextFile.path]
        }
        return []
    }

    function hasClipboardSource() {
        return selectedPaths.length > 0 || !!contextFile.path
    }

    function copySelected() {
        const paths = clipboardSourcePaths()
        if (!paths.length) {
            return
        }
        clipboardPaths = paths
        clipboardMode = "copy"
        fileOps.copyToClipboard(paths, false)
    }

    function cutSelected() {
        const paths = clipboardSourcePaths()
        if (!paths.length) {
            return
        }
        clipboardPaths = paths
        clipboardMode = "cut"
        fileOps.copyToClipboard(paths, true)
    }

    function pasteClipboard() {
        const systemPaths = fileOps.clipboardFilePaths()
        const pathsToPaste = systemPaths.length ? systemPaths : clipboardPaths
        const modeToPaste = systemPaths.length ? fileOps.clipboardMode() : clipboardMode
        if (!pathsToPaste.length || !modeToPaste) {
            return
        }

        let pastedPaths = []
        let completed = true
        for (let i = 0; i < pathsToPaste.length; i++) {
            const sourcePath = pathsToPaste[i]
            const targetPath = fileOps.uniquePath(currentPath, fileNameFromPath(sourcePath))
            if (!targetPath) {
                completed = false
                continue
            }

            const didPaste = modeToPaste === "cut"
                ? fileOps.moveItem(sourcePath, targetPath)
                : fileOps.copyItem(sourcePath, targetPath)
            completed = completed && didPaste
            if (didPaste) {
                pastedPaths.push(targetPath)
            }
        }

        if (modeToPaste === "cut" && completed) {
            clipboardPaths = []
            clipboardMode = ""
        }
        selectedPaths = pastedPaths
        reloadCurrentFolder()
    }

    function hasPasteSource() {
        return !!currentPath && (clipboardPaths.length > 0 || fileOps.hasClipboardFiles())
    }

    function copyPathToClipboard(path) {
        clipboardHelper.text = path
        clipboardHelper.selectAll()
        clipboardHelper.copy()
    }

    function reloadCurrentFolder() {
        folderModel.folder = ""
        folderModel.folder = fileUrl(currentPath)
        refreshVisibleModel()
    }

    FolderListModel {
        id: folderModel
        folder: root.fileUrl(root.currentPath)
        showDirs: true
        showFiles: true
        showDotAndDotDot: false
        showHidden: false
        sortField: FolderListModel.Name
        onCountChanged: root.refreshVisibleModel()
        onFolderChanged: root.refreshVisibleModel()
        Component.onCompleted: root.refreshVisibleModel()
    }

    ListModel {
        id: visibleModel
    }

    TextInput {
        id: clipboardHelper
        visible: false
    }

    onSearchTextChanged: refreshVisibleModel()

    component StyledMenuItem: MenuItem {
        id: menuItem
        property string iconText: ""
        property string shortcutText: ""

        implicitWidth: 236
        implicitHeight: 36
        opacity: enabled ? 1.0 : 0.46

        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: 7
                color: menuItem.highlighted && menuItem.enabled ? Theme.colors.accentSoft : Theme.colors.control
                border.width: 1
                border.color: Theme.colors.hairline

                Text {
                    anchors.centerIn: parent
                    text: menuItem.iconText
                    color: menuItem.highlighted && menuItem.enabled ? Theme.colors.accent : Theme.colors.textMuted
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            Text {
                Layout.fillWidth: true
                text: menuItem.text
                color: Theme.colors.textPrimary
                font.pixelSize: 13
                font.weight: menuItem.highlighted && menuItem.enabled ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: menuItem.shortcutText.length > 0
                text: menuItem.shortcutText
                color: Theme.colors.textFaint
                font.pixelSize: 11
                verticalAlignment: Text.AlignVCenter
            }
        }

        background: Rectangle {
            x: 6
            y: 2
            width: parent.width - 12
            height: parent.height - 4
            radius: 9
            color: menuItem.highlighted && menuItem.enabled ? Theme.colors.controlHover : "transparent"
        }
    }

    component StyledMenuSeparator: MenuSeparator {
        topPadding: 5
        bottomPadding: 5
        contentItem: Rectangle {
            implicitHeight: 1
            implicitWidth: 1
            color: Theme.colors.divider
        }
    }

    Menu {
        id: fileContextMenu
        width: 236

        margins: 8
        padding: 8

        background: Rectangle {
            implicitWidth: 236
            radius: 14
            color: Theme.colors.previewSurface
            border.width: 1
            border.color: Theme.colors.hairline

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 0.54
                shadowOpacity: root.darkMode ? 0.38 : 0.16
                shadowVerticalOffset: 12
            }
        }

        StyledMenuItem {
            text: "Open"
            iconText: "O"
            enabled: !!root.contextFile.path
            onTriggered: root.activate(root.contextFile.path, root.contextFile.isDir)
        }
        StyledMenuItem {
            text: "Open with Default App"
            iconText: "A"
            enabled: !!root.contextFile.path && !root.contextFile.isDir
            onTriggered: Qt.openUrlExternally(root.fileUrl(root.contextFile.path))
        }
        StyledMenuSeparator {}
        StyledMenuItem {
            text: "Copy"
            iconText: "C"
            shortcutText: "Ctrl+C"
            enabled: root.hasClipboardSource()
            onTriggered: root.copySelected()
        }
        StyledMenuItem {
            text: "Paste"
            iconText: "V"
            shortcutText: "Ctrl+V"
            enabled: root.hasPasteSource()
            onTriggered: root.pasteClipboard()
        }
        StyledMenuItem {
            text: "Cut"
            iconText: "X"
            shortcutText: "Ctrl+X"
            enabled: root.hasClipboardSource()
            onTriggered: root.cutSelected()
        }
        StyledMenuSeparator {}
        StyledMenuItem {
            text: "Copy Path"
            iconText: "P"
            enabled: !!root.contextFile.path
            onTriggered: root.copyPathToClipboard(root.contextFile.path)
        }
        StyledMenuItem {
            text: "Show Parent Folder"
            iconText: "F"
            enabled: !!root.contextFile.path
            onTriggered: {
                const slash = root.contextFile.path.lastIndexOf("/")
                if (slash > 0) {
                    root.navigate(root.contextFile.path.slice(0, slash))
                }
            }
        }
        StyledMenuSeparator {}
        StyledMenuItem {
            text: "Rename"
            iconText: "R"
            enabled: !!root.contextFile.path
            onTriggered: renamePopup.openFor(root.contextFile)
        }
        StyledMenuItem {
            text: "Move to Trash"
            iconText: "D"
            enabled: !!root.contextFile.path
            onTriggered: {
                if (fileOps.moveToTrash(root.contextFile.path)) {
                    root.selectedPaths = []
                    root.reloadCurrentFolder()
                }
            }
        }
        StyledMenuItem {
            text: "New Folder Here"
            iconText: "N"
            enabled: !!root.currentPath
            onTriggered: newFolderPopup.open()
        }
        StyledMenuSeparator {}
        StyledMenuItem {
            text: "Get Info"
            iconText: "I"
            enabled: !!root.contextFile.path
            onTriggered: infoPopup.openFor(root.contextFile)
        }
    }

    Popup {
        id: renamePopup
        modal: true
        focus: true
        width: 360
        height: 142
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        property var file: ({})

        function openFor(fileInfo) {
            file = fileInfo
            renameField.text = fileInfo.name
            open()
            renameField.forceActiveFocus()
            renameField.selectAll()
        }

        background: Rectangle {
            radius: 18
            color: Theme.colors.previewSurface
            border.width: 1
            border.color: Theme.colors.hairline
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Text {
                text: "Rename"
                color: Theme.colors.textPrimary
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            TextField {
                id: renameField
                Layout.fillWidth: true
                selectByMouse: true
                color: Theme.colors.textPrimary
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                Button { text: "Cancel"; onClicked: renamePopup.close() }
                Button {
                    text: "Done"
                    onClicked: {
                        if (fileOps.renameItem(renamePopup.file.path, renameField.text)) {
                            root.selectedPaths = []
                            root.reloadCurrentFolder()
                        }
                        renamePopup.close()
                    }
                }
            }
        }
    }

    Popup {
        id: newFolderPopup
        modal: true
        focus: true
        width: 360
        height: 142
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        onOpened: {
            newFolderField.text = "Untitled Folder"
            newFolderField.forceActiveFocus()
            newFolderField.selectAll()
        }

        background: Rectangle {
            radius: 18
            color: Theme.colors.previewSurface
            border.width: 1
            border.color: Theme.colors.hairline
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Text {
                text: "New Folder"
                color: Theme.colors.textPrimary
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            TextField {
                id: newFolderField
                Layout.fillWidth: true
                selectByMouse: true
                color: Theme.colors.textPrimary
                onAccepted: createButton.clicked()
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                Button { text: "Cancel"; onClicked: newFolderPopup.close() }
                Button {
                    id: createButton
                    text: "Create"
                    onClicked: {
                        if (fileOps.createFolder(root.currentPath, newFolderField.text)) {
                            root.reloadCurrentFolder()
                        }
                        newFolderPopup.close()
                    }
                }
            }
        }
    }

    Popup {
        id: infoPopup
        modal: true
        focus: true
        width: 420
        height: 230
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        property var file: ({})

        function openFor(fileInfo) {
            file = fileInfo
            open()
        }

        background: Rectangle {
            radius: 20
            color: Theme.colors.previewSurface
            border.width: 1
            border.color: Theme.colors.hairline
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            Text {
                text: infoPopup.file.name || "Item"
                color: Theme.colors.textPrimary
                font.pixelSize: 20
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text { text: infoPopup.file.path || ""; color: Theme.colors.textMuted; font.pixelSize: 12; elide: Text.ElideMiddle; Layout.fillWidth: true }
            Text { text: infoPopup.file.isDir ? "Kind: Folder" : "Kind: " + extensionLabel(infoPopup.file.name || "") + " file"; color: Theme.colors.textMuted; font.pixelSize: 13 }
            Text { text: infoPopup.file.isDir ? "" : "Size: " + formatSize(infoPopup.file.size || 0); color: Theme.colors.textMuted; font.pixelSize: 13 }
            Item { Layout.fillHeight: true }
            Button { Layout.alignment: Qt.AlignRight; text: "Close"; onClicked: infoPopup.close() }
        }
    }

    Rectangle {
        id: windowChrome
        anchors.fill: parent
        radius: Theme.radius.window
        color: Theme.colors.background
        clip: true
        border.width: 1
        border.color: Theme.colors.windowStroke

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.72
            shadowOpacity: root.darkMode ? 0.42 : 0.16
            shadowVerticalOffset: 18
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: sidebar
                Layout.fillHeight: true
                Layout.preferredWidth: 248
                color: Theme.colors.sidebarGlass

                Rectangle {
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: Theme.colors.divider
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 18

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 11
                            color: Theme.colors.accent

                            Text {
                                anchors.centerIn: parent
                                text: "R"
                                color: "white"
                                font.family: Theme.typography.heading
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: "Rootlink"
                                color: Theme.colors.textPrimary
                                font.family: Theme.typography.heading
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "Wayland Finder"
                                color: Theme.colors.textMuted
                                font.family: Theme.typography.body
                                font.pixelSize: 11
                            }
                        }
                    }

                    SidebarSection {
                        title: "Favorites"
                        entries: [
                            { label: "Applications", icon: "\uf135", path: "/usr/share/applications" },
                            { label: "Downloads", icon: "\uf019", path: homePath + "/Downloads" },
                            { label: "Desktop", icon: "\uf108", path: homePath + "/Desktop" },
                            { label: "Documents", icon: "\uf15c", path: homePath + "/Documents" }
                        ]
                    }

                    SidebarSection {
                        title: "Locations"
                        entries: [
                            { label: "Home", icon: "\uf015", path: homePath },
                            { label: "System", icon: "\uf0a0", path: "/" },
                            { label: "Mounted Drives", icon: "\uf1c0", path: "/run/media/" + userName },
                            { label: "Trash", icon: "\uf1f8", path: homePath + "/.local/share/Trash/files" }
                        ]
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 72
                        radius: 18
                        color: Theme.colors.panelSubtle
                        border.width: 1
                        border.color: Theme.colors.hairline

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 2

                            Text {
                                text: visibleModel.count + (root.searchText.length ? " matches" : " visible items")
                                color: Theme.colors.textPrimary
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.displayPath(root.currentPath)
                                color: Theme.colors.textMuted
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Rectangle {
                    id: toolbar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74
                    color: Theme.colors.toolbarGlass

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.colors.divider
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: 21
                            color: Theme.colors.control
                            border.width: 1
                            border.color: Theme.colors.hairline

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 8

                                Text {
                                    text: "\uf015"
                                    color: Theme.colors.textMuted
                                    font.family: Theme.typography.icon
                                    font.pixelSize: 15
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: currentFolderName(root.currentPath)
                                        elide: Text.ElideRight
                                        color: Theme.colors.textPrimary
                                        font.family: Theme.typography.heading
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.displayPath(root.currentPath)
                                        elide: Text.ElideMiddle
                                        color: Theme.colors.textMuted
                                        font.family: Theme.typography.body
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }

                        NavPill {
                            Layout.preferredWidth: 88
                            Layout.preferredHeight: 42
                        }

                        SearchField {
                            Layout.preferredWidth: 230
                            Layout.preferredHeight: 42
                            onQueryChanged: root.searchText = query
                        }

                        ThemeToggle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                        }

                        ViewSwitch {
                            currentMode: root.viewMode
                            onModeSelected: mode => root.viewMode = mode
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.colors.surface

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animation_duration_short }
                    }

                    GridView {
                        id: gridView
                        anchors.fill: parent
                        anchors.leftMargin: 28
                        anchors.rightMargin: 28
                        anchors.topMargin: root.searchText.length ? 72 : 28
                        anchors.bottomMargin: 28
                        visible: root.viewMode === "grid"
                        clip: true
                        model: visibleModel
                        cellWidth: 132 * root.iconScale
                        cellHeight: 142 * root.iconScale

                        add: Transition {
                            NumberAnimation { properties: "opacity,scale"; from: 0.84; to: 1; duration: 170; easing.type: Easing.OutCubic }
                        }

                        delegate: FileTile {
                            width: gridView.cellWidth - 10
                            height: gridView.cellHeight - 10
                            name: model.name
                            path: model.path
                            isDir: model.isDir
                            size: model.size
                            modified: model.modified
                            previewMode: false
                            selected: root.selectedPaths.indexOf(model.path) >= 0
                            onClicked: mouse => root.toggleSelection(model.path, mouse.modifiers)
                            onDoubleClicked: root.activate(model.path, model.isDir)
                            onContextRequested: mouse => root.openContextMenu({ name: model.name, path: model.path, isDir: model.isDir, size: model.size, modified: model.modified }, mouse)
                        }
                    }

                    GridView {
                        id: previewGridView
                        anchors.fill: parent
                        anchors.leftMargin: 28
                        anchors.rightMargin: 28
                        anchors.topMargin: root.searchText.length ? 72 : 28
                        anchors.bottomMargin: 28
                        visible: root.viewMode === "preview"
                        clip: true
                        model: visibleModel
                        cellWidth: 160 * root.iconScale
                        cellHeight: 170 * root.iconScale

                        delegate: FileTile {
                            width: previewGridView.cellWidth - 10
                            height: previewGridView.cellHeight - 10
                            name: model.name
                            path: model.path
                            isDir: model.isDir
                            size: model.size
                            modified: model.modified
                            previewMode: true
                            selected: root.selectedPaths.indexOf(model.path) >= 0
                            onClicked: mouse => root.toggleSelection(model.path, mouse.modifiers)
                            onDoubleClicked: root.activate(model.path, model.isDir)
                            onContextRequested: mouse => root.openContextMenu({ name: model.name, path: model.path, isDir: model.isDir, size: model.size, modified: model.modified }, mouse)
                        }
                    }

                    ListView {
                        id: listView
                        anchors.fill: parent
                        anchors.leftMargin: 22
                        anchors.rightMargin: 22
                        anchors.topMargin: root.searchText.length ? 68 : 18
                        anchors.bottomMargin: 18
                        visible: root.viewMode === "list"
                        clip: true
                        model: visibleModel
                        spacing: 4

                        delegate: FileRow {
                            width: listView.width
                            name: model.name
                            path: model.path
                            isDir: model.isDir
                            size: model.size
                            modified: model.modified
                            selected: root.selectedPaths.indexOf(model.path) >= 0
                            onClicked: mouse => root.toggleSelection(model.path, mouse.modifiers)
                            onDoubleClicked: root.activate(model.path, model.isDir)
                            onContextRequested: mouse => root.openContextMenu({ name: model.name, path: model.path, isDir: model.isDir, size: model.size, modified: model.modified }, mouse)
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 26
                        anchors.rightMargin: 26
                        anchors.topMargin: 18
                        height: 38
                        radius: 19
                        visible: root.searchText.length > 0
                        color: Theme.colors.control
                        border.width: 1
                        border.color: Theme.colors.hairline

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "⌕"
                                color: Theme.colors.accent
                                font.pixelSize: 14
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Searching this folder for \"" + root.searchText + "\""
                                color: Theme.colors.textPrimary
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Text {
                                text: visibleModel.count + " matches"
                                color: Theme.colors.textMuted
                                font.pixelSize: 12
                            }
                        }
                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    color: Theme.colors.statusBar

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18

                        Text {
                            Layout.fillWidth: true
                            text: root.selectedPaths.length ? root.selectedPaths.length + " selected" : visibleModel.count + (root.searchText.length ? " matches" : " items")
                            color: Theme.colors.textMuted
                            font.pixelSize: 12
                        }

                        Slider {
                            Layout.preferredWidth: 140
                            from: 0.82
                            to: 1.35
                            value: root.iconScale
                            visible: root.viewMode !== "list"
                            onValueChanged: root.iconScale = value
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 80, 420)
                        spacing: 10
                        visible: visibleModel.count === 0
                        z: 5

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 62
                            Layout.preferredHeight: 56
                            radius: 16
                            color: Theme.colors.control
                            border.width: 1
                            border.color: Theme.colors.hairline

                            Text {
                                anchors.centerIn: parent
                                text: root.searchText.length ? "\uf002" : "\uf07b"
                                color: Theme.colors.textMuted
                                font.family: Theme.typography.icon
                                font.pixelSize: 24
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.searchText.length ? "No matching files" : "This folder is empty"
                            color: Theme.colors.textPrimary
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.searchText.length ? "Try a different search in this folder." : root.displayPath(root.currentPath)
                            color: Theme.colors.textMuted
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideMiddle
                        }
                    }
                }
        }
    }

    component SidebarSection: ColumnLayout {
        property string title
        property var entries: []
        spacing: 6
        Layout.fillWidth: true

        Text {
            text: title.toUpperCase()
            color: Theme.colors.textFaint
            font.pixelSize: 10
            font.weight: Font.DemiBold
            leftPadding: 10
        }

        Repeater {
            model: entries
            delegate: Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 12
                color: mouseArea.containsMouse || root.currentPath === modelData.path ? Theme.colors.sidebarHover : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        text: modelData.icon
                        color: root.currentPath === modelData.path ? Theme.colors.accent : Theme.colors.textMuted
                        font.family: Theme.typography.icon
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        Layout.preferredWidth: 20
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: Theme.colors.textPrimary
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (String(modelData.path).indexOf("network://") === 0) {
                            Qt.openUrlExternally(modelData.path)
                        } else {
                            root.navigate(modelData.path)
                        }
                    }
                }
            }
        }
    }

    component CapsuleButton: Button {
        id: capsuleButton
        implicitWidth: 42
        implicitHeight: 38
        padding: 0
        opacity: enabled ? 1 : 0.42

        Behavior on opacity {
            NumberAnimation { duration: 130 }
        }

        background: Rectangle {
            radius: 19
            color: capsuleButton.down ? Theme.colors.controlPressed : (capsuleButton.hovered ? Theme.colors.controlHover : Theme.colors.control)
            border.width: 1
            border.color: Theme.colors.hairline
        }

        contentItem: Text {
            text: capsuleButton.text
            color: capsuleButton.enabled ? Theme.colors.textPrimary : Theme.colors.textFaint
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    component TrafficLight: Rectangle {
        property color dotColor: "#ff5f57"
        width: 12
        height: 12
        radius: 6
        color: dotColor
        border.width: 1
        border.color: Theme.colors.hairline
        opacity: 0.92
    }

    component NavPill: Rectangle {
        radius: height / 2
        color: Theme.colors.control
        border.width: 1
        border.color: Theme.colors.hairline

        RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 2

            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                enabled: root.backStack.length > 0
                padding: 0
                background: Rectangle {
                    radius: 18
                    color: parent.down ? Theme.colors.controlPressed : (parent.hovered ? Theme.colors.controlHover : "transparent")
                }
                contentItem: Text {
                    text: "\uf053"
                    color: parent.enabled ? Theme.colors.textPrimary : Theme.colors.textFaint
                    font.family: Theme.typography.icon
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.goBack()
            }

            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                enabled: root.forwardStack.length > 0
                padding: 0
                background: Rectangle {
                    radius: 18
                    color: parent.down ? Theme.colors.controlPressed : (parent.hovered ? Theme.colors.controlHover : "transparent")
                }
                contentItem: Text {
                    text: "\uf054"
                    color: parent.enabled ? Theme.colors.textPrimary : Theme.colors.textFaint
                    font.family: Theme.typography.icon
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.goForward()
            }
        }
    }

    component SearchField: Rectangle {
        id: searchField
        signal queryChanged(string query)
        radius: height / 2
        color: Theme.colors.control
        border.width: 1
        border.color: searchInput.activeFocus ? Theme.colors.accent : Theme.colors.hairline

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: "\uf002"
                color: Theme.colors.textMuted
                font.family: Theme.typography.icon
                font.pixelSize: 13
            }

            TextField {
                id: searchInput
                Layout.fillWidth: true
                placeholderText: "Search"
                placeholderTextColor: Theme.colors.textFaint
                color: Theme.colors.textPrimary
                font.pixelSize: 13
                selectByMouse: true
                background: Item {}
                onTextChanged: searchField.queryChanged(text)
            }

            Button {
                visible: searchInput.text.length > 0
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                padding: 0
                background: Rectangle {
                    radius: 12
                    color: parent.hovered ? Theme.colors.controlHover : "transparent"
                }
                contentItem: Text {
                text: "\uf00d"
                color: Theme.colors.textMuted
                font.family: Theme.typography.icon
                font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: searchInput.text = ""
            }
        }
    }

    component ThemeToggle: Button {
        id: themeToggle
        padding: 0
        hoverEnabled: true

        background: Rectangle {
            radius: height / 2
            color: themeToggle.down ? Theme.colors.controlPressed : (themeToggle.hovered ? Theme.colors.controlHover : Theme.colors.control)
            border.width: 1
            border.color: Theme.colors.hairline
        }

        contentItem: Text {
            text: Theme.colors.isDark ? "\uf185" : "\uf186"
            color: Theme.colors.textPrimary
            font.family: Theme.typography.icon
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        ToolTip.visible: hovered
        ToolTip.text: Theme.colors.isDark ? "Light mode" : "Dark mode"

        onClicked: Theme.colors.isDark = !Theme.colors.isDark
    }

    component ViewSwitch: Rectangle {
        id: viewSwitch
        property string currentMode: "grid"
        signal modeSelected(string mode)
        Layout.preferredWidth: 132
        Layout.preferredHeight: 42
        radius: 21
        color: Theme.colors.control
        border.width: 1
        border.color: Theme.colors.hairline

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4

            ModeButton {
                label: "\uf00a"
                mode: "grid"
                selected: viewSwitch.currentMode === mode
                onSelectedMode: mode => viewSwitch.modeSelected(mode)
            }
            ModeButton {
                label: "\uf03a"
                mode: "list"
                selected: viewSwitch.currentMode === mode
                onSelectedMode: mode => viewSwitch.modeSelected(mode)
            }
            ModeButton {
                label: "\uf03e"
                mode: "preview"
                selected: viewSwitch.currentMode === mode
                onSelectedMode: mode => viewSwitch.modeSelected(mode)
            }
        }
    }

    component ModeButton: Rectangle {
        property string label
        property string mode
        property bool selected: false
        signal selectedMode(string mode)
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 17
        color: selected ? Theme.colors.accent : "transparent"

        Text {
            anchors.centerIn: parent
            text: label
            color: selected ? "white" : Theme.colors.textMuted
            font.family: Theme.typography.icon
            font.pixelSize: 13
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: selectedMode(mode)
        }
    }

    component FileTile: Rectangle {
        id: tile
        property string name
        property string path
        property bool isDir
        property int size
        property date modified
        property bool previewMode: false
        property bool selected: false
        signal clicked(var mouse)
        signal doubleClicked()
        signal contextRequested(var mouse)

        radius: 18
        color: selected ? Theme.colors.selection : (tileMouse.containsMouse ? Theme.colors.tileHover : "transparent")
        scale: tileMouse.containsMouse ? 1.025 : 1.0

        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 70 * root.iconScale
                Layout.preferredHeight: 64 * root.iconScale
                radius: 18
                color: iconBackColor(name, isDir)
                border.width: 1
                border.color: Theme.colors.hairline
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    visible: tile.previewMode && isImageFile(name) && !isDir
                    source: root.fileUrl(path)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }

                Rectangle {
                    visible: isDir
                    x: 10
                    y: 10
                    width: 28
                    height: 10
                    radius: 5
                    color: Theme.colors.folderTab
                }

                Rectangle {
                    visible: !isDir && !(tile.previewMode && isImageFile(name))
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: 18
                    height: 18
                    radius: 4
                    color: Qt.lighter(iconBackColor(name, false), 1.22)
                    opacity: 0.7
                }

                Text {
                    anchors.centerIn: parent
                    visible: !(tile.previewMode && isImageFile(name) && !isDir)
                    text: fileIcon(name, isDir)
                    color: isDir ? "white" : iconTextColor(name)
                    font.family: Theme.typography.icon
                    font.pixelSize: isDir ? 24 : 26
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    visible: !isDir
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 7
                    width: Math.max(32, badgeText.implicitWidth + 14)
                    height: 18
                    radius: 9
                    color: "#33000000"

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: fileBadge(name)
                        color: "white"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: name
                color: Theme.colors.textPrimary
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {
                if (mouse.button === Qt.RightButton) {
                    tile.contextRequested(mouse)
                } else {
                    tile.clicked(mouse)
                }
            }
            onDoubleClicked: tile.doubleClicked()
        }
    }

    component FileRow: Rectangle {
        id: row
        property string name
        property string path
        property bool isDir
        property int size
        property date modified
        property bool selected: false
        property bool compact: false
        signal clicked(var mouse)
        signal doubleClicked()
        signal contextRequested(var mouse)

        height: compact ? 42 : 48
        radius: 14
        color: selected ? Theme.colors.selection : (rowMouse.containsMouse ? Theme.colors.tileHover : "transparent")

        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 14
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 26
                radius: 8
                color: iconBackColor(name, isDir)
                border.width: 1
                border.color: Theme.colors.hairline

                Text {
                    anchors.centerIn: parent
                    text: fileIcon(name, isDir)
                    color: isDir ? "white" : iconTextColor(name)
                    font.family: Theme.typography.icon
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
            }

            Text {
                Layout.fillWidth: true
                text: name
                color: Theme.colors.textPrimary
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                visible: !compact
                Layout.preferredWidth: 110
                text: isDir ? "Folder" : formatSize(size)
                color: Theme.colors.textMuted
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {
                if (mouse.button === Qt.RightButton) {
                    row.contextRequested(mouse)
                } else {
                    row.clicked(mouse)
                }
            }
            onDoubleClicked: row.doubleClicked()
        }
    }

    function extensionLabel(name) {
        const dot = name.lastIndexOf(".")
        if (dot < 0 || dot === name.length - 1) {
            return "FILE"
        }
        return name.slice(dot + 1, dot + 5).toUpperCase()
    }

    function currentFolderName(path) {
        if (!path || path === "/") {
            return "System"
        }
        const parts = path.split("/").filter(Boolean)
        if (!parts.length) {
            return "System"
        }
        if (homePath && path === homePath) {
            return "Home"
        }
        return parts[parts.length - 1]
    }

    function extension(name) {
        const dot = name.lastIndexOf(".")
        return dot >= 0 ? name.slice(dot + 1).toLowerCase() : ""
    }

    function isDotFile(name) {
        return name.length > 1 && name.charAt(0) === "."
    }

    function fileIcon(name, isDir) {
        if (isDir) return "\uf07b"
        const ext = extension(name)
        if (isDotFile(name)) return "\uf023"
        if (["desktop", "appimage", "app", "bin", "exe"].indexOf(ext) >= 0) return "\uf135"
        if (["ppt", "pptx", "pps", "ppsx", "odp", "key"].indexOf(ext) >= 0) return "\uf1c4"
        if (isImageFile(name)) return "\uf1c5"
        if (["mp4", "mkv", "webm", "mov", "avi"].indexOf(ext) >= 0) return "\uf1c8"
        if (["mp3", "flac", "wav", "ogg", "m4a"].indexOf(ext) >= 0) return "\uf1c7"
        if (["pdf"].indexOf(ext) >= 0) return "\uf1c1"
        if (["md", "txt", "rst"].indexOf(ext) >= 0) return "\uf15c"
        if (["rs", "cpp", "c", "h", "hpp", "qml", "js", "ts", "py", "go", "lua", "sh", "json", "toml", "yaml", "yml"].indexOf(ext) >= 0) return "\uf1c9"
        if (["zip", "tar", "gz", "xz", "7z", "rar"].indexOf(ext) >= 0) return "\uf1c6"
        return "\uf15b"
    }

    function isImageFile(name) {
        const ext = extension(name)
        return ["png", "jpg", "jpeg", "webp", "gif", "svg", "heic"].indexOf(ext) >= 0
    }

    function fileBadge(name) {
        const ext = extension(name)
        if (isDotFile(name)) return "HID"
        if (["desktop", "appimage", "app", "bin", "exe"].indexOf(ext) >= 0) return "APP"
        if (["ppt", "pptx", "pps", "ppsx", "odp", "key"].indexOf(ext) >= 0) return "PPT"
        if (!ext) return "FILE"
        if (ext.length > 4) return ext.slice(0, 4).toUpperCase()
        return ext.toUpperCase()
    }

    function iconBackColor(name, isDir) {
        if (isDir) return Theme.colors.folderBack
        const ext = extension(name)
        if (isDotFile(name)) return Theme.colors.typeHidden
        if (["desktop", "appimage", "app", "bin", "exe"].indexOf(ext) >= 0) return Theme.colors.typeApplication
        if (["ppt", "pptx", "pps", "ppsx", "odp", "key"].indexOf(ext) >= 0) return Theme.colors.typePresentation
        if (["png", "jpg", "jpeg", "webp", "gif", "svg", "heic"].indexOf(ext) >= 0) return Theme.colors.typeImage
        if (["mp4", "mkv", "webm", "mov", "avi"].indexOf(ext) >= 0) return Theme.colors.typeVideo
        if (["mp3", "flac", "wav", "ogg", "m4a"].indexOf(ext) >= 0) return Theme.colors.typeAudio
        if (ext === "pdf") return Theme.colors.typePdf
        if (["rs", "cpp", "c", "h", "hpp", "qml", "js", "ts", "py", "go", "lua", "sh", "json", "toml", "yaml", "yml"].indexOf(ext) >= 0) return Theme.colors.typeCode
        if (["zip", "tar", "gz", "xz", "7z", "rar"].indexOf(ext) >= 0) return Theme.colors.typeArchive
        if (["md", "txt", "rst"].indexOf(ext) >= 0) return Theme.colors.typeText
        return Theme.colors.fileBack
    }

    function iconTextColor(name) {
        return Theme.colors.typeTextOnColor
    }

    function formatSize(bytes) {
        if (!bytes) {
            return "0 B"
        }
        const units = ["B", "KB", "MB", "GB", "TB"]
        const index = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1)
        return (bytes / Math.pow(1024, index)).toFixed(index === 0 ? 0 : 1) + " " + units[index]
    }

    Shortcut { sequence: StandardKey.Back; onActivated: root.goBack() }
    Shortcut { sequence: "Alt+Left"; onActivated: root.goBack() }
    Shortcut { sequence: "Alt+Right"; onActivated: root.goForward() }
    Shortcut { sequence: "Ctrl+1"; onActivated: root.viewMode = "grid" }
    Shortcut { sequence: "Ctrl+2"; onActivated: root.viewMode = "list" }
    Shortcut { sequence: "Ctrl+3"; onActivated: root.viewMode = "preview" }
    Shortcut { sequence: "Ctrl+C"; onActivated: root.copySelected() }
    Shortcut { sequence: "Ctrl+V"; onActivated: root.pasteClipboard() }
    Shortcut { sequence: "Ctrl+X"; onActivated: root.cutSelected() }
    Shortcut { sequence: "Escape"; onActivated: root.selectedPaths = [] }
    Shortcut { sequence: "Return"; onActivated: if (root.selectedPaths.length) root.activate(root.selectedPaths[0], false) }
}
