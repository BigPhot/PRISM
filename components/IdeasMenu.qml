import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Studio.DesignEffects

Rectangle {
    id: ideaMenu
    width: parent.width; height: 160
    radius: 25
    border.color: "#fc5a03"

    gradient: Gradient {
        GradientStop { position: 0; color: "#282828" }
        GradientStop { position: 0.5; color: "#424242" }
        GradientStop { position: 1; color: "#f50e0e0e" }
    }

    DesignEffect {
        id: shadow
        layerBlurRadius: 0
        effects: [
            DesignDropShadow {
                // Adds a soft external shadow for depth
                color: "#212121"; spread: 3; showBehind: true
                offsetY: 4; offsetX: 4; blur: 5
            },
            DesignInnerShadow {
                // Adds a subtle inner white glow for bevel effect
                color: "#ffffff"; spread: -1
                offsetY: 2; offsetX: 2; blur: 7
            }
        ]
    }


    Text {
        id: title
        text: modelData.title
        color: "white"
        font.bold: true; font.pixelSize: 16
        anchors.left: parent.left; anchors.leftMargin: 15
        anchors.top: parent.top; anchors.topMargin: 10
        wrapMode: Text.Wrap; elide: Text.ElideRight
        maximumLineCount: 1
    }

    Text {
        id: description
        width: 345
        text: modelData.description
        color: "lightgray"
        font.pixelSize: 12
        anchors.left: parent.left; anchors.leftMargin: 15
        anchors.top: parent.top; anchors.topMargin: 40
        wrapMode: Text.Wrap; elide: Text.ElideRight
    }


    MouseArea {
        id: menuClickArea
        // Clicking toggles submenu visibility and updates submenu model and selection
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: {
            menuBackend.updateSubMenuItems(index, "idea");
            submenuList.model = menuBackend.SubMenuItems;
            menuBackend.setSelectedMenuIndex(index, "idea");
            submenuContainer.x = 15;
            submenuContainer.y = 161;
            submenuContainer.visible = !submenuContainer.visible;
        }

    }
}
