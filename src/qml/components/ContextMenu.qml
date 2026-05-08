import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Menu {
    id: contextMenu
    
    signal copyRequested()
    signal pasteRequested()
    signal deleteRequested()
    signal renameRequested()
    signal newFolderRequested()

    MenuItem {
        text: "Open"
        onClicked: {}
    }

    MenuSeparator {}

    MenuItem {
        text: "Copy"
        onClicked: contextMenu.copyRequested()
    }

    MenuItem {
        text: "Paste"
        enabled: false
        onClicked: contextMenu.pasteRequested()
    }

    MenuItem {
        text: "Cut"
        onClicked: {}
    }

    MenuSeparator {}

    MenuItem {
        text: "Rename"
        onClicked: contextMenu.renameRequested()
    }

    MenuItem {
        text: "Delete"
        onClicked: contextMenu.deleteRequested()
    }

    MenuItem {
        text: "Duplicate"
        onClicked: {}
    }

    MenuSeparator {}

    MenuItem {
        text: "New Folder"
        onClicked: contextMenu.newFolderRequested()
    }

    MenuItem {
        text: "New File"
        onClicked: {}
    }

    MenuSeparator {}

    MenuItem {
        text: "Get Info"
        onClicked: {}
    }

    MenuItem {
        text: "Add to Favorites"
        onClicked: {}
    }
}
