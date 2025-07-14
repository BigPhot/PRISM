// DevMenu.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Studio.DesignEffects

Rectangle {
    id: devMenu
    width: parent.width
    height: 160
    radius: 25
    border.color: "#fc5a03"

    gradient: Gradient {
        GradientStop { position: 0; color: "#282828" }
        GradientStop { position: 0.5; color: "#424242" }
        // Slight transparency at the bottom for layered effect
        GradientStop { position: 1; color: "#f50e0e0e" }
    }

    DesignEffect {
        id: shadow
        layerBlurRadius: 0
        // Combo of drop and inner shadows for visual depth and elevation
        effects: [
            DesignDropShadow {
                color: "#212121"
                spread: 3
                showBehind: true
                offsetY: 4
                offsetX: 4
                blur: 5
            },
            DesignInnerShadow {
                color: "#ffffff"
                spread: -1
                offsetY: 2
                offsetX: 2
                blur: 7
            }
        ]
    }

    // Title text (single-line, bold white)
    Text {
        id: title
        text: modelData.title
        color: "white"
        font.bold: true
        font.pixelSize: 16
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.top: parent.top
        anchors.topMargin: 10
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    // Description text (multi-line, smaller, light gray)
    Text {
        id: description
        text: modelData.description
        color: "lightgray"
        font.pixelSize: 12
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.top: parent.top
        anchors.topMargin: 40
        wrapMode: Text.Wrap
        elide: Text.ElideRight
    }

    // Main interactive area, handles both left and right clicks
    MouseArea {
        id: menuClickArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                // LEFT-CLICK: update and show submenu based on current index
                menuBackend.updateSubMenuItems(index, "dev")
                submenuList.model = menuBackend.SubMenuItems
                menuBackend.setSelectedMenuIndex(index, "dev")

                // Position submenu just below this Rectangle
                submenuContainer.x = 15
                submenuContainer.y = 161
                submenuContainer.visible = !submenuContainer.visible
            } else if (mouse.button === Qt.RightButton) {
                // RIGHT-CLICK: open context menu
                showContextMenu(mouse)
            }
        }

        // Context menu offering contextual actions
        Menu {
            id: mainContextMenu
            // Reference to the rectangle’s index
            property int parentIndex

            MenuItem {
                id: addContext
                text: "Add Context"
                // Triggered to allow adding contextual information to this block
                onTriggered: {
                    inputContainer.actionType = "context"
                    inputContainer.parentIndex = mainContextMenu.parentIndex
                    inputContainer.visible = true
                }
            }

            MenuItem {
                id: addStep
                text: "Add Step"
                // Triggered to allow adding a new step inside this block
                onTriggered: {
                    inputContainer.actionType = "add"
                    inputContainer.parentIndex = mainContextMenu.parentIndex
                    inputContainer.visible = true
                }
            }
        }

        // Displays the context menu at mouse position and sets its index
        function showContextMenu(mouse) {
            mainContextMenu.parentIndex = index
            mainContextMenu.x = mouse.x
            mainContextMenu.y = mouse.y
            mainContextMenu.open()
        }
    }
}
