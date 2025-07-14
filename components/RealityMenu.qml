import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Studio.DesignEffects

Rectangle {
    id: realityMenu
    // Rectangle fills parent width and fixed height, rounded corners and border color
    width: parent.width
    height: 160
    radius: 25
    border.color: "#fc5a03"

    // Background gradient from dark gray to lighter shades and nearly transparent at bottom
    gradient: Gradient {
        GradientStop { position: 0; color: "#282828" }
        GradientStop { position: 0.5; color: "#424242" }
        GradientStop { position: 1; color: "#f50e0e0e" }
    }

    // Design effects including drop shadow behind and subtle inner shadow
    DesignEffect {
        id: shadow
        layerBlurRadius: 0
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

    // Title text at top-left with white bold font, single line, ellipsis if overflow
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

    // Description text below title, light gray color, wraps with ellipsis for overflow
    Text {
        id: description
        width: 345
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

    // MouseArea covering entire rectangle, accepts left and right clicks
    MouseArea {
        id: menuClickArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        // On click: update submenu items and toggle submenu container visibility
        onClicked: {
            menuBackend.updateSubMenuItems(index, "rlty");
            submenuList.model = menuBackend.SubMenuItems;
            menuBackend.setSelectedMenuIndex(index, "rlty");

            // Position the submenu container just below this rectangle
            submenuContainer.x = 15;
            submenuContainer.y = 161;

            // Toggle visibility of the submenu container
            submenuContainer.visible = !submenuContainer.visible;
        }
    }
}
